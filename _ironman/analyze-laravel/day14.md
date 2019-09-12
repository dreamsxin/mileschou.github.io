---
title: 分析 Routing（3）
---

昨天在最後面，可以知道一件很重要的資訊：Router 裡面所指的 action 原形，其實是 array。以昨天的例子來說：

```php
$this->app->make('router')
    ->prefix('api')
    ->middleware('api')
    ->namespace($this->namespace)
    ->get('/', function() {
        return 'whatever';
    });
```

它會把這些資訊轉換 array，才產生 [Route][] 物件：

```php
[
    'prefix' => 'api',
    'middleware' => ['api'],
    'namespace' => $this->namespace,
    'uses' => function() {
        return 'whatever';
    },
];
```

Laravel 稱這個資訊為 action，了解這個，對後面要繼續追 code 是有幫助的。

> 某種程度而言，這也算是一種 domain knowledge。

再一次回味程式碼：

```php
$this->app->make('router')
     ->prefix('api')
     ->middleware('api')
     ->namespace($this->namespace)
     ->group(base_path('routes/api.php'));

$this->app->make('router')
     ->middleware('web')
     ->namespace($this->namespace)
     ->group(base_path('routes/web.php'));
```

昨天提到 `namespace()` 完之後，會得到一個 [RouteRegistrar][] 實例，並且把需要的 attributes 都存放在實例裡。

今天要繼續來看 `RouteRegistrar::group()` 做了什麼事：

```php
public function group($callback)
{
    $this->router->group($this->attributes, $callback);
}
```

其實很簡單，是呼叫 `Router::group()`：

```php
public function group(array $attributes, $routes)
{
    // 更新 stack
    $this->updateGroupStack($attributes);

    // 載入路由
    $this->loadRoutes($routes);

    // 移除 stack
    array_pop($this->groupStack);
}
```

會使用 stack 的理由約略可以猜想，因為下面這一種巢狀使用方法，是要能被接受的：

```php
Route::group([], function() {
    Route::group([], function() {
        Route::group([], function() {
            Route::get('/', function() {
                return 'whatever';
            });
        });
    });
});
```

為了保存各階段的設定，因此採用了 stack 的資料結構。

來看看 `updateGroupStack()` 做了什麼：

```php
protected function updateGroupStack(array $attributes)
{
    // 如果不是空的，則使用 RouteGroup::merge() 將目前的 $attributes 跟父層的合併 
    if (! empty($this->groupStack)) {
        $attributes = RouteGroup::merge($attributes, end($this->groupStack));
    }

    // 往 stack 推入一筆資料
    $this->groupStack[] = $attributes;
}
```

[RouteGroup][] 與 [BoundMethod][Day04] 一樣，是一個 helper 類別，裡面都是靜態方法。先來看 `RouteGroup::merge()` 做了什麼：

```php
public static function merge($new, $old)
{
    // 如果新設定有 domain 的話，就把舊設定給移除
    if (isset($new['domain'])) {
        unset($old['domain']);
    }

    // 重新格式化新設定
    $new = array_merge(static::formatAs($new, $old), [
        'namespace' => static::formatNamespace($new, $old),
        'prefix' => static::formatPrefix($new, $old),
        'where' => static::formatWhere($new, $old),
    ]);

    // 將舊設定與新設定合併
    return array_merge_recursive(Arr::except(
        $old, ['namespace', 'prefix', 'where', 'as']
    ), $new);
}
```

簡單來說這個方法的任務是：四個屬性 `namespace`、`prefix`、`where`、`as` 與舊設定會有特別的合併方法，然後再用新設定覆蓋舊設定。至於合併的方法都不難，可以直接參考原始碼吧。

取得合併後的資料就推入 stack 中，使用 `group()` 方法才會推 stack，因此數量與呼叫次數會是一樣的，`loadRoutes()` 之後就會移除。而 `loadRoutes()` 長這樣：

```php
protected function loadRoutes($routes)
{
    // 是 Closure 就呼叫它，不是的話，預期會是 filename，就 require 它
    if ($routes instanceof Closure) {
        $routes($this);
    } else {
        $router = $this;

        require $routes;
    }
}
```

偶爾會發生，需要傳 Closure，可是不確定參數裡面應該要有什麼，這時通常會翻原始碼來看。從這裡可以知道 `group()` 可以帶的 callback 長相是這樣：

```php
// 雖然平常都這樣寫
Route::group([], function() {
    Route::get('/', function() {
        return 'whatever';
    });
};

// 不過也可以這樣寫
Route::group([], function(Router $router) {
    $router->get('/', function() {
        return 'whatever';
    });
};
```

另外也會發現，`group()` 也可以帶 filename，而被 require 檔案的寫法，下面兩個是等價：

```php
Route::get('/', function() {
    return 'whatever';
});

$router->get('/', function() {
    return 'whatever';
});
```

> 這也是研究原始碼會發現的小趣事。

回到 stack 的用途，參考下面這段程式碼：

```php
// 設定 1
Route::group([], function() {
    // 設定 2
    Route::group([], function() {
        Route::get('/a', function() {
            return 'whatever';
        });
    });

    // 設定 3
    Route::group([], function() {
        Route::get('/b', function() {
            return 'whatever';
        });
    });
});
```

Router 不管使用 Application 建置或是 Facade，都會是單例。上面的 Route Facade 其實是對同一個實例做操作。執行的順序如下：

1.  設定 1 被載入後，會放在 stack 第一個位置
2.  設定 2 跟設定 1 合併，稱之設定 1 + 2，會推到 stack 第二個位置
3.  使用設定 1 + 2 設定 route
4.  清除 stack 第二筆資料
5.  設定 3 跟設定 1 合併，稱之設定 1 + 3，會推到 stack 第二個位置
6.  使用設定 1 + 3 設定 route
7.  清除 stack 第二筆資料
7.  清除 stack 第一筆資料

當使用 Router 的建立 Route 的方法時，就會拿 stack 最頂層的設定來用。

`group()` 方法的原理大致是這樣

[Route]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Routing/Route.php
[RouteGroup]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Routing/RouteGroup.php
[RouteRegistrar]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Routing/RouteRegistrar.php

[Day04]: day04.md
