---
title: 總結
---

這麼多天以來，看了很多 Laravel 的程式，其實可以發現它有一些常見的模式。沒有好壞，只是一種可參考的寫法：

### 在 if 裡做 assign

```php
if ($user = $this->resloveUser()) {
    $user->can('create');
}
```

這樣寫可以省一行定義，但 if 內的事務過於複雜就容易不知道 condition 的副作用為何。

### 判斷方法存在才呼叫

```php
if (method_exists($middleware, 'handle')) {
    return $middleware->handle();
}
```

曾有討論是反對這種寫法，因為會覺得直接定介面就好。但反過來說，如果定了介面，就無法改變參數的定義，如果想設計一個可長可短，同時要能自動注入的方法，就是件不可能的任務了：

```php
public function handle($request, $next);
public function handle($request, $next, $arg1);
public function handle($request, $next, $arg1, $arg2);
```

### 丟例外有時也會寫方法處理

```php
protected function getRouteForMethods($request, array $methods)
{
    // ...
    $this->methodNotAllowed($methods);
}

protected function methodNotAllowed(array $others)
{
    throw new MethodNotAllowedHttpException($others);
}
```

### 常使用 Fluent pattern 來表示一連串的事件流

通常要對同一個物件做操作，且前後操作是有相關聯的時候，使用 fluent pattern 更能感受到程式所想表達的意圖：

```php
Gate::allows('update-post', $post));

Gate::forUser($user)->allows('update-post', $post));
```

### 同個方法裡，流程控制區塊盡可能少

流程控制區塊指的是 if / for / foreach / while 等。這些流程都與循環複雜度呈正相關。如果越大，代表這段程式越難懂，也越容易出現 bug。目前有注意最多的地方在 Container，有七個流程控制。


### 流程控制多採用有問題先處理掉的寫法

比起下面兩種寫法，會是上面比較好懂一點。當流程控制區塊越多的時候，將會更明顯。

```php
if (!$user) {
    return false;
}

if (!is_callable($callback)) {
    return false;
}

return $callback($user);
```

另一種相反的寫法

```php
if ($user) {
    if (is_callable($callback)) {
        return $callback($user);
    }
}

return false;
```

## 後記

筆者時常說：

> 程式語言也是一種「語言」，跟自然語言有其相像的點。

這次的主題是分析原始碼，同時就有點像在做一個翻譯員，試圖自己了解，也讓各位讀者也能理解程式所想表達的意圖。

有趣的是，這過程就很像在讀小說會感受到文學的美一樣，會覺得程式這樣寫很好理解，甚至很酷。到了自己要寫文章－－也就是要寫程式時，就會回頭把酷炫的寫法「借」過來使用，同時也想讓更多人除了使用外，也能了解自己所寫的程式。

而更重要的，程式開發人員，最強大的地方在於，有能力可以理解與分析其他人寫的原始碼。分析原始碼，正是在培養工程師閱讀程式的能力。另外也增加判斷程式好壞能力的好方法，因為唯有同時看過好程式與爛程式，才有可能會知道什麼樣的程式是好的。

這三十天寫的分析，筆者盡可能寫出讓其他開發者能理解的描述，希望能幫助到大家。
