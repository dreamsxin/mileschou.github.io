---
title: 分析 Laravel Feature Test
---

今天要來分析內建測試是如何實作的，先來看官方[測試範例][ExampleTest]程式碼。

```php
public function testBasicTest()
{
    $response = $this->get('/');

    $response->assertStatus(200);
}
```

它對應會跑的 [Route][web.php] 如下：

```php
Route::get('/', function () {
    return view('welcome');
});
```

> Routing 的分析可以再回頭看 [Day12][]。

這幾會來看 Laravel 是如何從 `get()` 去取得 response，並得知 statue code 或其他結果。

## 共用的 Laravel TestCase

Laravel Framework 有一個抽象的 [TestCase][] 類別，首先要了解測試一開始初始化了哪些東西，這可以從 `setUp()` 得知：

```php
protected function setUp()
{
    // 初始化 Application
    if (! $this->app) {
        $this->refreshApplication();
    }

    // 初始化 trait
    $this->setUpTraits();

    // Application 初始化後的 hook
    foreach ($this->afterApplicationCreatedCallbacks as $callback) {
        call_user_func($callback);
    }

    // 清除 Facade 的 instance
    Facade::clearResolvedInstances();

    // 重新設定 Model 的 event
    Model::setEventDispatcher($this->app['events']);

    // 當初始化完成，做一個標記
    $this->setUpHasRun = true;
}
```

[Application][Day05] 是 Laravel 的核心，所以一開始得先初始化。

```php
protected function refreshApplication()
{
    $this->app = $this->createApplication();
}

// createApplication 預設是由 CreateApplication trait 實作的

public function createApplication()
{
    $app = require __DIR__.'/../bootstrap/app.php';

    $app->make(Kernel::class)->bootstrap();

    return $app;
}
```

[分析 bootstrap 流程][Day02]曾提過，`bootstrap/app.php` 的任務是提供一個可以用在任何場景的 Application，包括測試。而 `bootstrap()` 方法是為了載入必要的設定檔等，這樣測試程式碼才能正常使用 [Config][Day06] 等元件。

接著，如果 TestCase 有標記特定的 trait，如 DatabaseTransactions，就會有特定的行為，這個 magic 是由 `setUpTraits()` 所實作的。後面則是清除設定，讓測試可以從乾淨的狀態從頭執行。

`get()` 與其他 HTTP 相關的方法是寫在 [MakesHttpRequests][] 裡：

```php
public function get($uri, array $headers = [])
{
    // 將 header 轉成 server 的環境變數
    $server = $this->transformHeadersToServerVars($headers);

    // 呼叫 call
    return $this->call('GET', $uri, [], [], [], $server);
}
```

其他相關的 HTTP method 與 `get()` 一樣，最終都會呼叫 `call()`：

```php
public function call($method, $uri, $parameters = [], $cookies = [], $files = [], $server = [], $content = null)
{
    // 取得 HTTP Kernel
    $kernel = $this->app->make(HttpKernel::class);

    // 處理 file 參數
    $files = array_merge($files, $this->extractFilesFromDataArray($parameters));

    // 從各參數產生 symfony request
    $symfonyRequest = SymfonyRequest::create(
        $this->prepareUrlForRequest($uri), $method, $parameters,
        $cookies, $files, array_replace($this->serverVariables, $server), $content
    );

    // 呼叫 handle() 方法
    $response = $kernel->handle(
        $request = Request::createFromBase($symfonyRequest)
    );

    // 如果啟用 followRedirects 就再繼續呼叫 get() 方法，直到不再 redirect
    if ($this->followRedirects) {
        $response = $this->followRedirects($response);
    }

    // Request 結束
    $kernel->terminate($request, $response);

    // 建立 fesponse 測試輔助物件
    return $this->createTestResponse($response);
}
```

仔細觀察可以發現，它跟 [index.php][] 有很多相同的呼叫方法，而 index.php 有多呼叫 Response send 方法。

最後的 response 測試輔助物件則提供了 `assertStatus()` 等方法，來驗證最後的 response。

[ExampleTest]: https://github.com/laravel/laravel/blob/v5.7.0/tests/Feature/ExampleTest.php
[MakesHttpRequests]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Testing/Concerns/MakesHttpRequests.php
[TestCase]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Testing/TestCase.php
[index.php]: https://github.com/laravel/laravel/blob/v5.7.0/public/index.php
[web.php]: https://github.com/laravel/laravel/blob/v5.7.0/routes/web.php

[Day02]: day02.md
[Day05]: day05.md
[Day06]: day06.md
[Day12]: day12.md
