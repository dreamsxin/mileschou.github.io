---
title: 分析 bootstrap 流程－－Lumen 篇
---

與 Laravel 一樣，從進入點 [index.php][] 開始看起：

```php
$app = require __DIR__.'/../bootstrap/app.php';

$app->run();
```

Lumen 顯得非常簡單，只有拿 [Application][] 後，直接 run 即可。

而 bootstrap/app.php 如下：

```php
require_once __DIR__.'/../vendor/autoload.php';

// 載 .env
try {
    (new Dotenv\Dotenv(__DIR__.'/../'))->load();
} catch (Dotenv\Exception\InvalidPathException $e) {
    //
}

// 建構 Lumen Application，並帶入主要目錄
$app = new Laravel\Lumen\Application(
    realpath(__DIR__.'/../')
);

// 設定 container
$app->singleton(
    Illuminate\Contracts\Debug\ExceptionHandler::class,
    App\Exceptions\Handler::class
);

$app->singleton(
    Illuminate\Contracts\Console\Kernel::class,
    App\Console\Kernel::class
);

// 註冊 route
$app->router->group([
    'namespace' => 'App\Http\Controllers',
], function ($router) {
    require __DIR__.'/../routes/web.php';
});

return $app;
```

回顧之前[分析 bootstrap][Day02]，這裡多了載 .env 與註冊 route 兩件事。這意味著 Lumen Application 並沒有處理這兩件事。

> 載 .env 是 Bootstrapper [LoadEnvironmentVariables][] 所初始化的，Router 則是在 [App\Providers\RouteServiceProvider::boot()][Day12] 的時候註冊的。

不僅如此，從註解的說明可以知道，Lumen 預設很多事都沒有做，如 [ServiceProvider][Day05] 需要從頭來；[Middleware][Day20] 也要重頭來；[Facade][Day23] 需要另外設定，等。

來看 Lumen Application 的建構子有多精簡：

```php
public function __construct($basePath = null)
{
    if (! empty(env('APP_TIMEZONE'))) {
        date_default_timezone_set(env('APP_TIMEZONE', 'UTC'));
    }

    $this->basePath = $basePath;

    // 初始化 Container，註冊基本必要的 instance 與 alias
    $this->bootstrapContainer();
    
    // 註冊錯誤處理，是 Laravel Bootstrap\HandleExceptions 的任務
    $this->registerErrorHandling();
    
    // 初始化 Router，其實裡面就是 new Router
    $this->bootstrapRouter();
}
```

大致上，原本 Laravel 會跑的 Bootstrap 任務，全都精簡化放在這裡了。

最後就是執行 `run()` 方法，它寫在 [RoutesRequests][] 這個 trait 裡：

```php
public function run($request = null)
{
    // Dispatcher 由 Lumen Application 擔任，處理完取得 Response
    $response = $this->dispatch($request);

    // 將 response 送出給瀏覽器
    if ($response instanceof SymfonyResponse) {
        $response->send();
    } else {
        echo (string) $response;
    }

    // 執行 terminable middleware
    if (count($this->middleware) > 0) {
        $this->callTerminableMiddleware($response);
    }
}
```

從 Request 可以傳 null 可得知，這同時也是提供了方便測試的接口。

> Slim 也可以這麼做。

明天再繼續看 `dispatch()` 方法裡面做了什麼。

[index.php]: https://github.com/laravel/lumen/blob/v5.7.0/public/index.php
[Application]: https://github.com/laravel/lumen-framework/blob/v5.7.6/src/Application.php
[RoutesRequests]: https://github.com/laravel/lumen-framework/blob/5.7/src/Concerns/RoutesRequests.php
[LoadEnvironmentVariables]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Bootstrap/LoadEnvironmentVariables.php

[Day02]: day02.md
[Day05]: day05.md
[Day12]: day12.md
[Day20]: day20.md
[Day23]: day23.md
