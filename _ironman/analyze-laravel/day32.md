---
title: Redirector 與 UrlGenerator 的關係
---

假設 routes 定義了以下路由：

```php
Route::get('/', 'IndexController@welcome')->name('welcome');
```

我們可以使用下面的方法取得 URL：

```php
route('welcome');
```

先大概了解這個實作方法：

```php
function route($name, $parameters = [], $absolute = true)
{
    return app('url')->route($name, $parameters, $absolute);
}
```

這個 `url` 曾在一開始[分析 Routing][day12] 的時候提到過，它所對應的類別是 [UrlGenerator][]，註冊方法如下：

```php
$this->app->singleton('url', function ($app) {
    $routes = $app['router']->getRoutes();

    $app->instance('routes', $routes);

    // UrlGenerator 建構子需要 RouteCollection 與 Request
    $url = new UrlGenerator(
        $routes, $app->rebinding(
            'request', $this->requestRebinder()
        )
    );

    // Session 解析器
    $url->setSessionResolver(function () {
        return $this->app['session'];
    });

    // APP_KEY 解析器
    $url->setKeyResolver(function () {
        return $this->app->make('config')->get('app.key');
    });

    // 當 RouteCollection 觸發 rebind 事件時，就重新設定給 UrlGenerator
    $app->rebinding('routes', function ($app, $routes) {
        $app['url']->setRoutes($routes);
    });

    return $url;
});
```

`route()` 函式，實際上是呼叫 UrlGenerator 的 `route()` 方法

```php
public function route($name, $parameters = [], $absolute = true)
{
    // 看看 RouteCollection 用名稱能不能找到
    if (! is_null($route = $this->routes->getByName($name))) {
        // 找到將會使用 RouteUrlGenerator 產生 url
        return $this->toRoute($route, $parameters, $absolute);
    }

    // 找不到就讓它爆
    throw new InvalidArgumentException("Route [{$name}] not defined.");
}
```

接著來看看 [Redirector][]。Laravel 也有提供 helper 函式：

```php
function redirect($to = null, $status = 302, $headers = [], $secure = null)
{
    if (is_null($to)) {
        return app('redirect');
    }

    return app('redirect')->to($to, $status, $headers, $secure);
}
```

這個函式提供兩種用法：

```php
redirect(); // 取得 Redirector
redirect('/path'); // 取得 RedirectResponse
```

註冊方法如下：

```php
$this->app->singleton('redirect', function ($app) {
    $redirector = new Redirector($app['url']);

    // 如果有 session 的話就設定
    if (isset($app['session.store'])) {
        $redirector->setSession($app['session.store']);
    }

    return $redirector;
});
```

Redirector 建構需要有 UrlGenerator。也因此兩個 helper 函式搭配後，下面的寫法都是通的：

```php
redirect(route('welcome'));
redirect()->to(route('welcome'));
redirect()->route('welcome');
redirect()->action('IndexController@welcome');
```

這樣的設計是很有趣且可以學習的，Redirector 本身提供了基本的 `to()` 與 `away()` 方法，可以導頁到指定的地方外，配合 UrlGenerator 與 Session 還可以做到 `route()`、`action()`、`back()` 等，與 Application 本身或狀態相關的導頁。

這是一個使用物件組合功能的好例子。

[Redirector]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Routing/Redirector.php
[UrlGenerator]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Routing/UrlGenerator.php

[day12]: day12.md
