---
title: 分析 Routing（5）
---

[Route][] 帶有單一個路由的資訊。從它在 Router 如何被初始化的程式碼，可以知道它有哪些基本的資訊。

```php
protected function newRoute($methods, $uri, $action)
{
    return (new Route($methods, $uri, $action))
                ->setRouter($this)
                ->setContainer($this->container);
}
```

建構子有三個重要的資訊：`$methods`、`$uri`、`$action`，其中 method 與 uri 很明顯是用來讓開發者定義最基本的資訊，而 action 則是其他資訊。

這些資訊都是用來比對（match）目前的 url 是否符合這個 route 的設定。

Route 建構子裡面其實還有做一些事：

```php
public function __construct($methods, $uri, $action)
{
    $this->uri = $uri;
    $this->methods = (array) $methods;
    
    // 解析 $action
    $this->action = $this->parseAction($action);

    // 如果有 GET 卻沒有 HEAD，就補上
    if (in_array('GET', $this->methods) && ! in_array('HEAD', $this->methods)) {
        $this->methods[] = 'HEAD';
    }

    // 如果有 prefix 的話，就 normalize 並加到 `uri` 屬性前面（prepend）
    if (isset($this->action['prefix'])) {
        $this->prefix($this->action['prefix']);
    }
}
```

解析 action 做了很多事，主要寫在 RouteAction 類別裡，使用靜態呼叫：

```php
public static function parse($uri, $action)
{
    // 沒有 $action 不會報錯，但會給一個丟例外的 Closure，直到被呼叫的時候才會丟例外
    if (is_null($action)) {
        return static::missingAction($uri);
    }

    // 是 Callable 的可能有兩種：Closure 與 array
    if (is_callable($action)) {
        // 如果是 Closure，設定 uses 就好；如果是 array 就設定 uses 與 controler
        return ! is_array($action) ? ['uses' => $action] : [
            'uses' => $action[0].'@'.$action[1],
            'controller' => $action[0].'@'.$action[1],
        ];
    }

    // 如果 action 的 uses 沒設定的話，則會嘗試在 action array 裡，找到第一個 Closure
    elseif (! isset($action['uses'])) {
        $action['uses'] = static::findCallable($action);
    }

    // 如果是字串，而且不是 controller@method 的型式的話，會預期它是類別名，並實作 __invoke 函式
    if (is_string($action['uses']) && ! Str::contains($action['uses'], '@')) {
        $action['uses'] = static::makeInvokable($action['uses']);
    }

    return $action;
}
```

`makeInvokable()` 裡面是幫原本的類別名，後面加上 `@__invoke` 而已，同時它也是實作 [Single Action Controllers](https://laravel.com/docs/5.7/controllers#single-action-controllers) 的關鍵程式碼。

簡單來說，整個過程最後的目的是要回傳出一個可以使用的 action array。

接著，回到昨天提到的 `addRoute()`：
           
```php
public function addRoute($methods, $uri, $action)
{
   return $this->routes->add($this->createRoute($methods, $uri, $action));
}
```

這裡使用了 [RouteCollection][] 來新增 Route 實例，`add()` 裡面有偷做了一些事：

```php
public function add(Route $route)
{
    // 新增至 collection
    $this->addToCollections($route);

    // 新增對照表
    $this->addLookups($route);

    return $route;
}

protected function addToCollections($route)
{
    // 組 url
    $domainAndUri = $route->getDomain().$route->uri();

    // 設定 method、url 與 Route 實例的對應
    foreach ($route->methods() as $method) {
        $this->routes[$method][$domainAndUri] = $route;
    }

    // 這裡還特別設定了一個所有 Route 實例的對應
    $this->allRoutes[$method.$domainAndUri] = $route;
}

protected function addLookups($route)
{
    // 如果有設定 name 的話，就加入對照表
    if ($name = $route->getName()) {
        $this->nameList[$name] = $route;
    }

    $action = $route->getAction();

    // 如果是 Controller，也設定對照表
    if (isset($action['controller'])) {
        $this->addToActionList($action, $route);
    }
}

protected function addToActionList($action, $route)
{
    // 設定 action 與 Route 的對照表
    $this->actionList[trim($action['controller'], '\\')] = $route;
}
```

看完上面的程式碼，可以知道新增的過程中，其實 RouteCollection 是在忙著建對照表。

如果還有印象的話，在開始講 [Routing][Day12] 時，曾有講到這段程式碼：

```php
$this->app['router']->getRoutes()->refreshNameLookups();
$this->app['router']->getRoutes()->refreshActionLookups();
```

現在或許會知道它在做什麼了：

```php
public function refreshNameLookups()
{
    // 清除 name 的對照表
    $this->nameList = [];

    // 重新設定 name
    foreach ($this->allRoutes as $route) {
        if ($route->getName()) {
            $this->nameList[$route->getName()] = $route;
        }
    }
}

public function refreshActionLookups()
{
    // 清除 action 的對照表
    $this->actionList = [];

    // 重新設定 Controller 對照表
    foreach ($this->allRoutes as $route) {
        if (isset($route->getAction()['controller'])) {
            $this->addToActionList($route->getAction(), $route);
        }
    }
}
```

對照表從屬性來看，總共會有四種

```php
protected $routes = [];
protected $allRoutes = [];
protected $nameList = [];
protected $actionList = [];
```

這些對照表會用在不同的 get 方法上：

```php
// 使用 method 屬性來查 Route
public function get($method = null)
{
    return is_null($method) ? $this->getRoutes() : Arr::get($this->routes, $method, []);
}

// 使用 name 屬性來查 Route
public function getByName($name)
{
    return $this->nameList[$name] ?? null;
}

// 使用 Controller 名來查 Route
public function getByAction($action)
{
    return $this->actionList[$action] ?? null;
}

// 取得所有 Route
public function getRoutes()
{
    return array_values($this->allRoutes);
}

// 取得所有 Route 並依 method 屬性分類
public function getRoutesByMethod()
{
    return $this->routes;
}

// 取得所有 Route 並以 name 做 key 
public function getRoutesByName()
{
    return $this->nameList;
}
```

還有許多 has 方法，這些都會在 Router 要查實例的時候派上用場。

到今天為止，已經知道保存 Route 實例的空間是如何管理的。但在[分析 Pipeline][Day07] 時，有看到下面這段程式碼：

```php
return (new Pipeline($this->app))
            ->send($request)
            ->through($this->app->shouldSkipMiddleware() ? [] : $this->middleware)
            ->then($this->dispatchToRouter());
```

`dispatchToRouter()` 究竟是如何找到對應的 Route 實例，並執行的呢？這應該是更神奇的事，就請待下回分曉囉。

[Route]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Routing/Route.php
[RouteCollection]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Routing/RouteCollection.php
[Router]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Routing/Router.php

[Day07]: day07.md
[Day12]: day12.md
