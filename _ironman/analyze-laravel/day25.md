---
title: 分析 Auth（2）
---

透過 [AuthManager][] 取得 [SessionGuard][] 實例，接著在 [Authenticate Middleware][] 會呼叫 `check()` 方法驗證：

```php
if ($this->auth->guard($guard)->check()) {
    return $this->auth->shouldUse($guard);
}
```

SessionGuard 的 `check()` 方法如下：

```php
public function check()
{
    return ! is_null($this->user());
}
```

只要呼叫 `user()` 的結果不是 null，即是驗證成功。從介面上來看，它應該會回傳 Authenticatable 或是 null：

```php
public function user()
{
    // 已登出就回傳 null
    if ($this->loggedOut) {
        return;
    }

    // 如果屬性 user 有值就回傳
    if (! is_null($this->user)) {
        return $this->user;
    }

    // 從 session 取得代表使用者的 id 
    $id = $this->session->get($this->getName());

    // 如果有取到 id，且從 provider 也能取回實例的話，就觸發 Authenticated 事件
    if (! is_null($id) && $this->user = $this->provider->retrieveById($id)) {
        $this->fireAuthenticatedEvent($this->user);
    }

    // 取得 recaller 實例。這個實例是從 remember cookie 建出來的
    // 從原始碼還不確定，不過應該指的就是「記住我」的按鈕功能
    $recaller = $this->recaller();

    // 如果沒取到 user 實例，但有 recaller 的話
    if (is_null($this->user) && ! is_null($recaller)) {
        // 試著從 recaller 解析出 user 實例
        $this->user = $this->userFromRecaller($recaller);

        if ($this->user) {
            // 解析出來後，將 id 更新回 session
            $this->updateSession($this->user->getAuthIdentifier());

            // 使用 recaller 對 Auth 元件而言，是屬於 Login 事件
            $this->fireLoginEvent($this->user, true);
        }
    }

    return $this->user;
}
```

第一次進網站時，沒有 session 也沒有 cookie，因此最後回傳的會是 null，`check()` 方法將會回傳 false。

那反過來說，何時會回傳 true 呢？session 能取得 id 是一種可能，我們可以從使用 session 屬性方法來查，關鍵更新 session 的方法是 `updateSession()`：

```php
protected function updateSession($id)
{
    $this->session->put($this->getName(), $id);

    $this->session->migrate(true);
}
```

這個方法除了在上面 recaller 的行為也有看到之外，還有 `login()`，這也是 StatefulGuard 的介面：

```php
public function login(AuthenticatableContract $user, $remember = false)
{
    // 先更新 session，它的值正是 user 的 identifier
    $this->updateSession($user->getAuthIdentifier());

    // 有點記住我的話，就寫入 cookie
    if ($remember) {
        // 確保 user 的 remember token 存在，不存在會建新的
        $this->ensureRememberTokenIsSet($user);

        // 加入 CookieJar 的 queue
        // 換言之，使用 login() 方法的 route，必須要加上 AddQueuedCookiesToResponse 的 middleware 才會有作用
        $this->queueRecallerCookie($user);
    }

    // 觸發 Login 事件
    $this->fireLoginEvent($user, $remember);

    // 設定會員實例
    $this->setUser($user);
}
```

仔細想想，user 不可能丟一個物件進來登入，因此這個 login 方法，應該有被另一個處理 user 輸入的方法使用到，是 `attempt()` 方法：

```php
public function attempt(array $credentials = [], $remember = false)
{
    // 觸發嘗試驗證的事件
    $this->fireAttemptEvent($credentials, $remember);

    // 使用 credentials 去 provider 取得 Authenticatable 實例
    $this->lastAttempted = $user = $this->provider->retrieveByCredentials($credentials);

    // 驗證 credentials
    if ($this->hasValidCredentials($user, $credentials)) {
        // 呼叫登入方法
        $this->login($user, $remember);

        return true;
    }

    // 驗證失敗就觸發 Failed 事件
    $this->fireFailedEvent($user, $credentials);

    return false;
}
```

基本上使用帳密，透過 `attempt()`，即可完成登入流程。若再往上一層級追程式碼的話，就會到 Controller 了，先暫時打住。

回頭看一下 middleware 的 `$this->auth->shouldUse($guard)`：

```php
public function shouldUse($name)
{
    // 以剛剛的例子，這裡會是 null，所以會取得預設的 driver 為 web
    $name = $name ?: $this->getDefaultDriver();

    // 設定預設的 driver
    $this->setDefaultDriver($name);

    // 重新設定 Authenticatable 解析器
    $this->userResolver = function ($name = null) {
        return $this->guard($name)->user();
    };
}
```

昨天有提到 middleware 可以傳入多個 guard 驗證。因驗證 user 這件事，對 PHP 的生命週期來說，會是全域唯一的設定；這個方法則是用來設定目前全域唯一要用哪一個 guard。

接著，有登入，也要有登出。來看一下如何登出。

剛剛有看到有一個屬性 `loggedOut` 是在代表是否執行過登出的 flag。反查了一下，找到 `logout()` 方法正是在設定這個屬性為 true：

```php
public function logout()
{
    // 解析 Authenticatable 實例
    $user = $this->user();

    // 清除 session 與 cookie
    $this->clearUserDataFromStorage();

    // 可以的話，重產 remember token
    if (! is_null($this->user)) {
        $this->cycleRememberToken($user);
    }

    // 有 event 物件的話，觸發登出事件
    if (isset($this->events)) {
        $this->events->dispatch(new Events\Logout($this->name, $user));
    }

    // 清除 guard 裡，有關 user 的資訊
    $this->user = null;

    // 設定屬性 loggedOut 為 true
    $this->loggedOut = true;
}
```
    
跟 `login()` 不一樣的是，它不依賴任何參數，可以直接在 Controller 呼叫它即可。

到此，簡單的 Authenticate 流程都說明完了。知道這些資訊後，就能使用 Auth 套件實作登入登出了，明天再來談如何客製化登入登出。

[AuthManager]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Auth/AuthManager.php
[Authenticate Middleware]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Auth/Middleware/Authenticate.php
[SessionGuard]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Auth/SessionGuard.php
