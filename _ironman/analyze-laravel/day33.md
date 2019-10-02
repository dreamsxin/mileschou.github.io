---
title: 如何正確地在 Response 加 Header（1）
---

前一陣子，朋友在社群分享小知識。

> $routeMiddleware 裡面的 middleware 加上 $header 的話會有問題，要在 $middleware 宣告才能保證生效

因為剛好筆者正在研究 Laravel 原始碼，所以就認真翻了一下。

Response header 是在[分析 bootstrap 流程][Day02]有提到 [`index.php`](https://github.com/laravel/laravel/blob/v5.7.0/public/index.php) 的這行程式碼才會送出：

```php
$response->send();
```

因此只要了解 $response 如何建構，以及 Pipeline 經過了哪些關卡、被做了哪些修改，就能知道真正問題點在哪了。

## Response 如何被建構出來的

在 middleware 裡，我們會預期 `$next($request)` 回來的結果會是 [Response][] 物件。這可以在 [Router][] 裡找到蛛絲馬跡。在分析 Routing 時，有提到 [`runRouteWithinStack()`][Day18] 的實作，裡面在執行 Pipeline 的程式碼如下：

```php
return (new Pipeline($this->container))
                ->send($request)
                ->through($middleware)
                ->then(function ($request) use ($route) {
                    // 實際執行 route 的地方在這裡：$route->run()
                    return $this->prepareResponse(
                        $request, $route->run()
                    );
                });
```

根據 [Pipeline][Day07] 的分析，`$next($request)` 拿到的結果，正是 `prepareResponse()` 的回傳結果。換句話說，它就是建構 Response 的方法。

回顧一下 [`prepareResponse()`][Day18] 的實作，事實上有機會對 Response 做處理的，只有下面這兩個方法：

```php
$response->setNotModified();

$response->prepare($request);
```

在[解析 Middleware 的實作細節][Day20]的時候，有提到 Pipeline 會被使用兩次，一次是上面所說的，也就是朋友所提到的 $routeMiddleware；另一次則是 $middleware，也就是在 [Http Kernel][] 的這段程式碼：

```php
protected function sendRequestThroughRouter($request)
{
    // 略

    return (new Pipeline($this->app))
                ->send($request)
                ->through($this->app->shouldSkipMiddleware() ? [] : $this->middleware)
                ->then($this->dispatchToRouter());
}
```

而 `dispatchToRouter()` 一直到 `runRouteWithinStack()` 的 call stack 如下：

```php
Kernel::dispatchToRouter();
Router::dispatch();
Router::dispatchToRoute();
Router::runRoute();
Router::runRouteWithinStack();
```

這過程中，還有另一次 `prepareResponse()`，但如同上面 `runRouteWithinStack()` 所說，其實對 header 並沒有特別修改什麼。

因此可以知道建構與 Pipeline 過程，理論上不會影響 response header。

---

今天先看建構過程與 Pipeline 流程是否有問題，明天再來看預設的 middleware 是否有偷偷對 header 做什麼處理。

[Http Kernel]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Http/Kernel.php
[Router]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Routing/Pipeline.php
[Pipeline]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Http/Response.php
[Router]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Routing/Router.php

[Day02]: day02.md
[Day07]: day07.md
[Day18]: day18.md
[Day20]: day20.md
