---
title: 分析 Lumen Application－－dispatch() 下篇
---

繼續看 [RoutesRequests][] 下面的方法。

* `createDispatcher()`
* `sendExceptionToHandler()`
* `prepareResponse()`

## createDispatcher()

Lumen 並沒有使用 Laravel 的 [Routing][Day12]，而是使用自定義的 [Router][]，把 Router 和 FastRoute 結合的就是這個方法：

```php
protected function createDispatcher()
{
    return $this->dispatcher ?: \FastRoute\simpleDispatcher(function ($r) {
        foreach ($this->router->getRoutes() as $route) {
            $r->addRoute($route['method'], $route['uri'], $route['action']);
        }
    });
}
```

simpleDispatcher 是 FastRoute 提供 Dispatcher 的工廠方法。傳入的 `$r` 會是 FastRoute 專用的 RouteCollection。可以看到它使用 `addRoute()` 把 Lumen Router 存放的 Route 再轉存到 FastRoute Collection 裡。

最後 dispatcher 屬性，將會是 FastRoute 的 Dispatcher。

## sendExceptionToHandler()

```php
protected function sendExceptionToHandler($e)
{
    // 這裡將會取得 ExceptionHandler 實例
    $handler = $this->resolveExceptionHandler();

    // 轉換 Error 為 FatalThrowableError
    if ($e instanceof Error) {
        $e = new FatalThrowableError($e);
    }

    // 這裡的 report 與 render 和 Laravel 的使用方法大同小異
    $handler->report($e);

    return $handler->render($this->make('request'), $e);
}
```

> Laravel 的 ErrorHandler 分析可以參考 [Day31 分析自定義錯誤頁][Day31]

## prepareResponse()

Laravel 也有 [prepareResponse()][Day18]，Lumen 就像是精簡版一樣：

```php
public function prepareResponse($response)
{
    $request = app(Request::class);

    // 轉換 Responsable
    if ($response instanceof Responsable) {
        $response = $response->toResponse($request);
    }

    // 轉換 PSR7 Response
    if ($response instanceof PsrResponseInterface) {
        $response = (new HttpFoundationFactory)->createResponse($response);
        
    // 若不是 Symfony Response 的實例，則預期會是字串，直接依字串產生 response
    } elseif (! $response instanceof SymfonyResponse) {
        $response = new Response($response);

    // 轉換 BinaryFileResponse
    } elseif ($response instanceof BinaryFileResponse) {
        $response = $response->prepare(Request::capture());
    }

    // 處理 Header 後回傳
    return $response->prepare($request);
}
```

---

以上就是 `dispatch()` 詳細分析的過程，接著明天再來看 [Router][] 的實作。

[Router]: https://github.com/laravel/lumen-framework/blob/v5.7.6/src/Routing/Router.php 
[RoutesRequests]: https://github.com/laravel/lumen-framework/blob/v5.7.6/src/Concerns/RoutesRequests.php

[Day12]: day12.md
[Day18]: day18.md
[Day31]: day31.md
