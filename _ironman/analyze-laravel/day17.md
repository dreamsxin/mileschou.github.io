---
title: 分析 Routing（6）
---

回過頭來，我們來看 [Http Kernel][] 的這段程式碼：

```php
return (new Pipeline($this->app))
            ->send($request)
            ->through($this->app->shouldSkipMiddleware() ? [] : $this->middleware)
            ->then($this->dispatchToRouter());
```

這是產生最終 Response 的過程。其中 Middleware 的原理已經在 [Pipeline][Day07] 分析過了；[Router][Day12] 基本運作原理也分析了。今天要來看的是，`dispatchToRouter()` 到底是如何選到符合的 Route。

一樣把原始碼打開：

```php
protected function dispatchToRouter()
{
    return function ($request) {
        $this->app->instance('request', $request);

        return $this->router->dispatch($request);
    };
}
```

這裡回傳了一個 Closure，它會被放到 Pipeline 裡執行。而傳入的 `$request`，即為 Pipeline 傳入的 `send($request)`。

拿到 request 之後，立刻設定到 [Container][Day03] 裡。這代表在這個時機點之後，才能開始使用 [`request()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/helpers.php#L718-L731) 取得 Request 實例。

這裡呼叫了 [Router][] 的 `dispatch()` 方法：

```php
public function dispatch(Request $request)
{
    // 記錄目前的 Request 實例
    $this->currentRequest = $request;

    return $this->dispatchToRoute($request);
}

public function dispatchToRoute(Request $request)
{
    // 透過 request 找到 Route 實例，並執行它
    return $this->runRoute($request, $this->findRoute($request));
}
```

繼續看 `findRoute()`：

```php
protected function findRoute($request)
{
    // 從 RouteCollection 找到 match 的 Route 實例，並記錄起來
    $this->current = $route = $this->routes->match($request);

    // 將 match 的 Route 實例，記錄在 Container 裡
    $this->container->instance(Route::class, $route);

    return $route;
}
```

這裡會看到，實際 match 的工作是交由 RouteCollection 處理的。

```php
public function match(Request $request)
{
    // 先依 request 的 method 取得符合 method 的 Route
    $routes = $this->get($request->getMethod());

    // 使用 request 跟這堆 Route 比比看
    $route = $this->matchAgainstRoutes($routes, $request);

    // 如果有找到，就把 request 綁定到 Route 上，並回傳出去
    if (! is_null($route)) {
        return $route->bind($request);
    }

    // 找不到的話，看一下有沒有其他 method 剛好也符合  
    $others = $this->checkForAlternateVerbs($request);

    // 有的話，就嘗試取得替代 Route 並回傳 
    if (count($others) > 0) {
        return $this->getRouteForMethods($request, $others);
    }

    // 全部的 Route 都沒找到，就是 404
    throw new NotFoundHttpException;
}
```

再來，因為每個方法都有分析的價值，所以下面會一個一個來看。首先看 `matchAgainstRoutes()` 是如何找到匹配的 Route：

```php
protected function matchAgainstRoutes(array $routes, $request, $includingMethod = true)
{
    // 先把 Fallback Route 跟正常的 Route 分開
    list($fallbacks, $routes) = collect($routes)->partition(function ($route) {
        return $route->isFallback;
    });

    // 再把 Fallback Route 放到最後一個
    // 接著所有的 Route 依序呼叫 matches()，找出哪一個 Route 是第一個匹配這次的 request 
    return $routes->merge($fallbacks)->first(function ($value) use ($request, $includingMethod) {
        return $value->matches($request, $includingMethod);
    });
}
```

因為使用了 `Collection::first()`，因此比對 Request 與 Route 就會有順序，這也是 Route 先設定會先匹配的原因。另外，建構對照表也是照設定順序，因此後設定的會把前面設定的覆蓋。

```php
public function matches(Request $request, $includingMethod = true)
{
    // 先把 Route 轉換成 CompiledRoute 實例
    $this->compileRoute();

    // 取得 Validator 
    foreach ($this->getValidators() as $validator) {
        // 如果不須要驗 method 的話，就跳過 MethodValidator
        if (! $includingMethod && $validator instanceof MethodValidator) {
            continue;
        }

        // 使用 Validator 來驗證 Route 與 Request 是否匹配，當有任一 Validator 不匹配的話，就會直接中止
        if (! $validator->matches($this, $request)) {
            return false;
        }
    }

    return true;
}
```

預設的 Validator 如下，這也是驗證 Route 與 Request 的基本判斷方法：

* UriValidator - 確認 Uri 是否匹配，同時這也是最複雜的比對，不過主要都是 Symfony 的套件完成了
* MethodValidator - 確認 Method 是否匹配
* SchemeValidator - 如果有設定 http / https 的話，就會比對
* HostValidator - 如果有設定 Domain 的話，就會比對

回到 match() 的流程，`bind()` 蠻單純的，先跳過，來看 `checkForAlternateVerbs()`：

```php
protected function checkForAlternateVerbs($request)
{
    // 因為要找的是替代的 method 所以先取出其他 method
    $methods = array_diff(Router::$verbs, [$request->getMethod()]);

    $others = [];

    // 將所有可能的 method 都找一下
    foreach ($methods as $method) {
        // 注意 matchAgainstRoutes() 第三個參數是 false，因為這裡是找其他 method 的可能性
        if (! is_null($this->matchAgainstRoutes($this->get($method), $request, false))) {
            $others[] = $method;
        }
    }

    // 最後回傳是 array，內容是 method 名稱
    return $others;
}
```

如果有找到任何可能的 method，再來就會呼叫 `getRouteForMethods()`：

```php
protected function getRouteForMethods($request, array $methods)
{
    // 如果 request 是 OPTIONS，就立刻創建一個新的 Route
    if ($request->method() == 'OPTIONS') {
        // Action 會回傳可用的 method 在 Allow header 裡 
        return (new Route('OPTIONS', $request->path(), function () use ($methods) {
            return new Response('', 200, ['Allow' => implode(',', $methods)]);
        }))->bind($request);
    }

    // 不是的話，就丟 405 出去，同時也把 Allow header 加上去
    $this->methodNotAllowed($methods);
}
```

當正常找找不到，找替代的也找不到，那麼就是 404 找不到了。

到了今天，總算知道 Route 是怎麼被匹配出來的了，但還有另一個主題：`runRoute()`，它是如何執行的，這就留到明天再繼續分析。

[Http Kernel]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Http/Kernel.php
[Router]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Routing/Router.php

[Day03]: day03.md
[Day07]: day07.md
[Day12]: day12.md
