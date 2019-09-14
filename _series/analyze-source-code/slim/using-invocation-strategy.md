---
title: Using Invocation Strategy
layout: collections
tags: [Slim Framework]
---

> 參考 [v3.12.1](https://github.com/slimphp/Slim/tree/3.12.1)

如同它的名稱，它實作了 Strategy Pattern。首先會有一個 [`InvocationStrategyInterface`][]，它只定義一個方法。原始碼如下：

```php
/**
 * Invoke a route callable.
 *
 * @param callable               $callable The callable to invoke using the strategy.
 * @param ServerRequestInterface $request The request object.
 * @param ResponseInterface      $response The response object.
 * @param array                  $routeArguments The route's placholder arguments
 *
 * @return ResponseInterface|string The response from the callable.
 */
public function __invoke(
    callable $callable,
    ServerRequestInterface $request,
    ResponseInterface $response,
    array $routeArguments
);
```

這裡的 `$callable`，是從存裡 Route 的 callable 解析出來的。因為有可能會這樣打：

```php
$app->get('/', '\HomeController:home');
```

必須要從字串解析成 callable，當然這就會是另一個角色－－[`CallableResolverInterface`][] 的任務。而另外三個參數則是官方文件 [Route callbacks](http://www.slimframework.com/docs/v3/objects/router.html#route-callbacks) 所提到的三個參數。

Slim 提供兩個預設實作，分別是 [`RequestResponse`][] 與 [`RequestResponseArgs`][]。只是前者才是預設的行為，後者是可選的行為。這就是 Strategy Pattern 的優點，演算法是可以自由切換的，切換的方法後面會再描述。

## 它是如何被使用？

上面知道了介面與實作的關係，還有參數的用途，那它是什麼時候被使用的呢？使用 IDE 反查功能可以找到，是在 [`Route::invoke()`][] 裡呼叫的：

```php
$handler = isset($this->container) ? $this->container->get('foundHandler') : new RequestResponse();
```

> 這裡可以知道，Strategy 是可以透過 container 注入來替換的。

## 回頭看看實作

預設行為實作如下：

```php
public function __invoke(
    callable $callable,
    ServerRequestInterface $request,
    ResponseInterface $response,
    array $routeArguments
) {
    foreach ($routeArguments as $k => $v) {
        $request = $request->withAttribute($k, $v);
    }

    return call_user_func($callable, $request, $response, $routeArguments);
}
```

中間的 foreach 先不看，先來比對官方的 GET 範例：

```php
$app = new \Slim\App();
$app->get('/books/{id}', function ($request, $response, $args) {
    // Show book identified by $args['id']
});
```

從這兩份片段原始碼可以了解，Route 的 callable 是如何被執行的。

這也是為什麼需要 `$args` 變數，即使 `$request` 或 `$response` 變數都用不到，我們還是得三個都打上去才能正常運作。

## 客製化 Invocation Strategy

從上面的分析可以了解，如果我們想像 [Laravel](/src/ironman-analyze-laravel/day18.md) 一樣，傳入什麼 class 都自動注入，其實這在 Slim 的架構上可以很容易做到。

比方說我們可以改成這樣寫：

```php
public function __invoke(
    callable $callable,
    ServerRequestInterface $request,
    ResponseInterface $response,
    array $routeArguments
) {
    foreach ($routeArguments as $k => $v) {
        $request = $request->withAttribute($k, $v);
    }

    return $this->container->call($callable, [$routeArguments]);
}
```

Route 定義就能改成如下：

```php
$app = new \Slim\App();
$app->get('/books/{id}', function (Request $request, $args) {
    // no response variable
});
```

## References

* [Laravel Bridge for Slim Framework](https://github.com/laravel-bridge/slim/tree/master) - 參考實作

[`InvocationStrategyInterface`]: https://github.com/slimphp/Slim/blob/3.12.1/Slim/Interfaces/InvocationStrategyInterface.php
[`CallableResolverInterface`]: https://github.com/slimphp/Slim/blob/3.12.1/Slim/Interfaces/CallableResolverInterface.php
[`RequestResponse`]: https://github.com/slimphp/Slim/blob/3.12.1/Slim/Handlers/Strategies/RequestResponse.php
[`RequestResponseArgs`]: https://github.com/slimphp/Slim/blob/3.12.1/Slim/Handlers/Strategies/RequestResponseArgs.php
[`Route::invoke()`]: https://github.com/slimphp/Slim/blob/3.12.1/Slim/Route.php#L354
