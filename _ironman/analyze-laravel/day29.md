---
title: 分析 Auth（6）－－Authorization
---

[Laravel 文件](https://laravel.com/docs/5.7/authorization#authorizing-actions-using-policies)有提到幾種方法來確認授權。

* Via The User Model
* Via Middleware
* Via Controller Helpers
* Via Blade Templates

> 不討論 Blade Templates 的部分，因為這會牽扯到 View，太複雜了。

以下先假設有這樣的設定：

```php
Gate::define('update-post', function ($user, $post) {
    return $user->id == $post->user_id;
});
```

> 官方提供的範例都會有兩種：正常狀況與不需指定 Model 的操作（*Actions That Don't Require Models*），但分析起來其實沒什麼太大差異。

## User Model

官方提供的範例如下：

```php
use App\Post;

if ($user->can('update', $post)) {
}

if ($user->can('create', Post::class)) {
}
```

來看 `can()` 的原始碼，它寫在 [Illuminate\Foundation\Auth\Access\Authorizable][]：

```php
public function can($ability, $arguments = [])
{
    return app(Gate::class)->forUser($this)->check($ability, $arguments);
}
```

寫得非常的好理解，它透過 `forUser()` 來把自己代入，接著再呼叫 `check()` 檢查。

## Authorize Middleware

官方提供的範例如下：

```php
use App\Post;

Route::put('/post/{post}', function (Post $post) {

})->middleware('can:update,post');

Route::post('/post', function () {

})->middleware('can:create,App\Post');
```

與驗證類似，授權也有專用的 Middleware，就叫 [Authorize][]。它的 `handle()` 實作如下：

```php
public function handle($request, Closure $next, $ability, ...$models)
{
    $this->gate->authorize($ability, $this->getGateArguments($request, $models));

    return $next($request);
}
```

`getGateArguments()` 會將 $models 參數做 normalize，這部分就不看了。這裡很直接，就呼叫 `authorize()` 而已。

```php
public function authorize($ability, $arguments = [])
{
    // 取得執行 policy 後的結果
    $result = $this->raw($ability, $arguments);

    // 如果是 Access Response instance 就直接回傳 
    if ($result instanceof Response) {
        return $result;
    }

    // 不是的話，預期會是 true / false，分別對應到 allow() 與 deny() 方法
    return $result ? $this->allow() : $this->deny();
}
```

這裡跟 `check()` 有點類似，不過差別在它回傳的固定會是 Response。如果是 bool 的話，則會使用 `allow()` 或 `deny()` 轉換成 Response 或 Exception：

```php
protected function allow($message = null)
{
    return new Response($message);
}

protected function deny($message = 'This action is unauthorized.')
{
    throw new AuthorizationException($message);
}
```

## Controller Helpers

官方提供的範例如下：

```php
use App\Post;

class PostController extends Controller
{
    use AuthorizesRequests;

    public function update(Request $request, Post $post)
    {
        $this->authorize('update', $post);
    }
    
    public function create(Request $request)
    {
        $this->authorize('create', Post::class);
    }
}
```

`authorize()` 方法寫在 [Illuminate\Foundation\Auth\Access\AuthorizesRequests][] 裡面

```php
public function authorize($ability, $arguments = [])
{
    list($ability, $arguments) = $this->parseAbilityAndArguments($ability, $arguments);

    return app(Gate::class)->authorize($ability, $arguments);
}
```

與 middleware 類似的，它也會先解析 ability 與 arguments，才傳入 Gate 的 `authorize()` 方法。

到此，Authorization 的分析差不多就結束了，相信大家對於授權會有更進一步的了解。

[Authorize]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Auth/Middleware/Authorize.php
[Illuminate\Foundation\Auth\Access\AuthorizesRequests]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Auth/Access/AuthorizesRequests.php
[Illuminate\Foundation\Auth\Access\Authorizable]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Auth/Access/Authorizable.php
