---
title: 分析 Routing（4）
---

今天要接著來看，是如何設定各式各樣的 route 了。先來看 `get()` 與 `post()` 的原始碼：

```php
public function get($uri, $action = null)
{
    return $this->addRoute(['GET', 'HEAD'], $uri, $action);
}

public function post($uri, $action = null)
{
    return $this->addRoute('POST', $uri, $action);
}
```

這裡可以知道，實際做事的是 `addRoute()`：

```php
public function addRoute($methods, $uri, $action)
{
    return $this->routes->add($this->createRoute($methods, $uri, $action));
}
```

`RouteCollection::add()` 是新增一筆 Route 並把該 Route 實例回傳。這樣的設計是為了讓後面的 fluent pattern 可以更加直觀：

```php
Route::get('/', function() {
    return 'whatever';
})->name('some-name');
```

`createRoute()` 則是建立 Route 實例：

```php
protected function createRoute($methods, $uri, $action)
{
    // 如果 $action 是 controller@method 的寫法的話，把它轉成 Controller Action
    if ($this->actionReferencesController($action)) {
        $action = $this->convertToControllerAction($action);
    }

    // 產生實例
    $route = $this->newRoute(
        $methods, $this->prefix($uri), $action
    );

    // 如果昨天的 groupStack 有東西，就將設定寫到 route 裡
    if ($this->hasGroupStack()) {
        $this->mergeGroupAttributesIntoRoute($route);
    }

    // 把 where 設定寫入 route
    $this->addWhereClausesToRoute($route);

    return $route;
}
```

> 順帶一提，可以發現 Laravel 在撰寫主要邏輯時，都會寫的比較白話；當追查後面實作才會覺得比較「技術」。

`actionReferencesController()` 的任務是確認 Action 是不是指向 Controller：

```php
protected function actionReferencesController($action)
{
    // 當不是 Closure，而且是 string 或者是 ['uses' => string] 的話，就假定它是 Controller
    if (! $action instanceof Closure) {
        return is_string($action) || (isset($action['uses']) && is_string($action['uses']));
    }

    return false;
}
```

轉換成 array 是呼叫 `convertToControllerAction()`：

```php
protected function convertToControllerAction($action)
{
    // 最終還是轉 array
    if (is_string($action)) {
        $action = ['uses' => $action];
    }

    // 如果 group stack 有東西的話，那 group 設定的 namespace 必須要加到 Controller 的前面
    if (! empty($this->groupStack)) {
        $action['uses'] = $this->prependGroupNamespace($action['uses']);
    }

    // 複製一份給 controller key
    $action['controller'] = $action['uses'];

    return $action;
}
```

`prependGroupNamespace()` 裡面有一段判斷可以看一鑑：

```php
return isset($group['namespace']) && strpos($class, '\\') !== 0
        ? $group['namespace'].'\\'.$class : $class;
```

`isset($group['namespace'])` 應該不用多解釋，有趣的地方是 `strpos($class, '\\') !== 0`，這代表如果 Controller 給絕對路徑的 namespace 的話，是不會受到 group 的 namespace 影響的。假設我有一個 Controller，完整類別名為 `\App\Http\Controllers\HelloController` 則下面兩個是等價的：

> 文件其實沒有講到這個用法，要翻原始碼才會知道

```php
// 假設預設 namespace 是 App\Http\Controllers

Route::get('foo', 'HelloController@method');
Route::get('foo', '\App\Http\Controllers\HelloController@method');
```

準備好 Action 後，就可以建構 Route 實例了。建構完 Route，會確認有沒有 group stack，有的話就呼叫 `$this->mergeGroupAttributesIntoRoute()` 合併 group stack 設定到 Route 實例裡

```php
protected function mergeGroupAttributesIntoRoute($route)
{
    // 先取得既有 Action 再跟最後一個 group 設定合併，然後再設定回 Route 實例
    $route->setAction($this->mergeWithLastGroup($route->getAction()));
}
```

最後，呼叫 `addWhereClausesToRoute()` 把 global where 設定加進 Route 實例裡。

```php
protected function addWhereClausesToRoute($route)
{
    $route->where(array_merge(
        $this->patterns, $route->getAction()['where'] ?? []
    ));

    return $route;
}
```

這裡其實就是實作 [Global Constraints][] 的功能。為何下面的 `pattern()` 設定會變成全域有效，就是上面這段程式碼實作出來的。

```php
Route::pattern('id', '[0-9]+');

Route::get('user/{id}/{name}', function ($id, $name) {
    //
})->where(['name' => '[a-z]+']);
```

同時也可以知道 Route 所設定的 where 是 array 多筆的形式。

到目前為止，Router 跟設定有關的程式碼都看的差不多了，我們可以發現 Router 本身跟設定相關最核心的任務，其實就是產生 Action 並建構 Route 實例。而 Route 實例也不存放在 Router，而是放在 RouteCollection。這就是標準的 facade pattern，所有控制後面角色行為的互動，都可以靠 facade，也就是 Router 來處理；而且，facade pattern 的一個特色是，因為這三天已經知道必要的參數是哪些了，所以是可以繞過 Router 自己來處理的。

明天再來繼續看 Route 如何存放與處理 Action 的資訊。

[Global Constraints]: https://laravel.com/docs/5.7/routing#parameters-regular-expression-constraints
