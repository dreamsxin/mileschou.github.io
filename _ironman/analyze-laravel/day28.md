---
title: 分析 Auth（5）－－Authorization
---

繼續昨天，來看 Policy 怎麼串接的，一樣是那個範例：

```php
// Policy 定義法
Gate::define('update-post', 'PostPolicy@update');

if (Gate::allows('update-post', $post)) {
}
```

昨天有提到關鍵程式碼在 `define()` 裡呼叫的 `buildAbilityCallback()`：

```php
protected function buildAbilityCallback($ability, $callback)
{
    return function () use ($ability, $callback) {
        // 這裡的判斷跟 Routing 差不多，就不解釋了
        if (Str::contains($callback, '@')) {
            [$class, $method] = Str::parseCallback($callback);
        } else {
            $class = $callback;
        }

        // $app->make($class) 它一下
        $policy = $this->resolvePolicy($class);

        // 取得所有參數
        $arguments = func_get_args();

        // 第一個是 user
        $user = array_shift($arguments);

        // 呼叫 before hook
        $result = $this->callPolicyBefore(
            $policy, $user, $ability, $arguments
        );

        // before hook 有結果的話，就先回傳
        if (! is_null($result)) {
            return $result;
        }

        // 沒有的話就呼叫 Policy
        return isset($method)
                ? $policy->{$method}(...func_get_args())
                : $policy(...func_get_args());
    };
}
```

因為本身是包裝成 Closure，所以後面的流程都跟原本 Closure 沒有差異。

另外一個會用到 Policy 的地方在 [Support\Providers\AuthServiceProvider][]，它可以覆寫 policies 屬性，並使用 `registerPolicies()` 來註冊被定義的 Policy：

```php
public function registerPolicies()
{
    foreach ($this->policies as $key => $value) {
        Gate::policy($key, $value);
    }
}
```

`policy()` 的任務單純是註冊 Policy：

```php
public function policy($class, $policy)
{
    $this->policies[$class] = $policy;

    return $this;
}
```

註冊的方法，官方的範例如下：

```php
Gate::policy(Post::class, PostPolicy::class);
```

這個註冊方法，它不會在 `abilities` 屬性加東西，所以後面解析 callback 的流程會跟原本 callback 並不一樣，主要在 `resolveAuthCallback()` 下面這個片段程式碼：

```php
if (isset($arguments[0]) &&
    ! is_null($policy = $this->getPolicyFor($arguments[0])) &&
    $callback = $this->resolvePolicyCallback($user, $ability, $arguments, $policy)) {
    return $callback;
}
```

先來看看 `getPolicyFor()` 是怎麼取得 Policy 的：

```php
public function getPolicyFor($class)
{
    if (is_object($class)) {
        $class = get_class($class);
    }

    // 預期是 class 字串
    if (! is_string($class)) {
        return;
    }

    // 如果有設定在 policies 裡的話，就 $app->make() 一下
    if (isset($this->policies[$class])) {
        return $this->resolvePolicy($this->policies[$class]);
    }

    // 如果沒設定的話，就查看看跟即有設定是不是有子類的繼承關係，是的話就用它
    foreach ($this->policies as $expected => $policy) {
        if (is_subclass_of($class, $expected)) {
            return $this->resolvePolicy($policy);
        }
    }
}
```

有了 Policy 的物件後，再來看看 `resolvePolicyCallback()` 是如何解析出 callback 的：

```php
protected function resolvePolicyCallback($user, $ability, array $arguments, $policy)
{
    // 格式化 ability 後，跟 policy 一起看是不是 callable
    if (! is_callable([$policy, $this->formatAbilityToMethod($ability)])) {
        return false;
    }

    // 再回傳一個新的 callback，這個 callback 與上面 class@method 的 callback 非常像
    return function () use ($user, $ability, $arguments, $policy) {
        // 呼叫 before hook
        $result = $this->callPolicyBefore(
            $policy, $user, $ability, $arguments
        );

        // 如果有拿到 result 的話就回傳
        if (! is_null($result)) {
            return $result;
        }

        // 解析出 method
        $method = $this->formatAbilityToMethod($ability);

        // 呼叫 Policy method
        return $this->callPolicyMethod($policy, $method, $user, $arguments);
    };
}

protected function formatAbilityToMethod($ability)
{
    // 有 `-` 字元就轉成 camel 格式，否則不變動
    return strpos($ability, '-') !== false ? Str::camel($ability) : $ability;
}
```

最後看看 `callPolicyMethod()` 是怎麼呼叫的

```php
protected function callPolicyMethod($policy, $method, $user, array $arguments)
{
    // 如果第一個參數是字串的話，代表那是解析 policy 用的 class name，就移掉
    if (isset($arguments[0]) && is_string($arguments[0])) {
        array_shift($arguments);
    }

    // 確認是否為 callable
    if (! is_callable([$policy, $method])) {
        return null;
    }

    // 確認目前的 user 可以呼叫的話，就直接對 policy 呼叫 method
    if ($this->canBeCalledWithUser($user, $policy, $method)) {
        return $policy->{$method}($user, ...$arguments);
    }
}
```

---

回頭看官網的範例，假如有了一個 PostPolicy：

```php
class PostPolicy
{
    public function update(User $user, Post $post)
    {
        return $user->id === $post->user_id;
    }
}
```

配合剛剛提到的設定，與呼叫 `allows()`：

```php
Gate::policy(Post::class, PostPolicy::class);

if (Gate::allows('update', $post)) {
}
```

如此呼叫後，經過上面的分析，程式到了 `resolveAuthCallback()` 時的 $arguments 會長的像下面這樣：

```php
$arguments = [
    $post,
];
```

而 `getPolicyFor()` 的參數將會是 $post，因此取到的 policy 實例會是 PostPolicy。緊接著 `resolvePolicyCallback()` 在確認 callable 時，傳入的參數將會是：

```php
[PostPolicy, 'update']
```

這是可以呼叫的 callable，所以會通過並產生 callback。確認目前的 user 是否能呼叫 `canBeCalledWithUser()`，因為這次是明確的 class + method，所以會使用 `methodAllowsGuests()` 來確認是否 guest 能呼叫。

剩下的分析就與 Closure 定義的方法沒有什麼差異了。

明天會來分析，各種確認權限的方法，背後是如何實作的。

[Support\Providers\AuthServiceProvider]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Support/Providers/AuthServiceProvider.php
