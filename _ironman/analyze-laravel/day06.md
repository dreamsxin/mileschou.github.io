---
title: 分析 Config
---

看完了 Container 後，接著看所有元件裡，最簡單的－－[Config][]，它的功能非常單純，是一個存放設定的空間，因此很容易理解原理。

## 類別圖

如同[第一天][Day01]所說，它依賴了 [Contracts][]，另外還有依賴 [Support][]。

先來看一下 UML 圖：

![](http://www.plantuml.com/plantuml/png/XP31JiCm38RlUGeVTjW4smCWG9iuSOLhBoPrjmWtYM87gIfxTqecHDUAShF-_xFYBtjHJ9fRDiuhfGOjmLFmcj2gLCFKk6FrGZ68qv0ww0t03VJu9WKvmmbblNgdRZCjZgIbk8LLJGrcLdW0dvbd93AlPw7yhdyWP_fhEIQAvEihTWvbEKs8inaP7rB2xc0jYK3_NLd6ONpDCOQarL3_Y8kYEdlHteoZ8Zo9YaHvQkbBxpztEtXcpgtpg3GdpFYy_-cb4hRRnokjExZS2XQPpPvydLl-0W00)

PlantUML 原始碼如下：

```
@startuml
interface Contracts\Config\Repository {
  + {abstract} has($key)
  + {abstract} get($key, $default = null)
  + {abstract} all()
  + {abstract} set($key, $value = null)
  + {abstract} prepend($key, $value)
  + {abstract} push($key, $value)
}

interface ArrayAccess {
}

class Support\Arr {
  + {static} has()
  + {static} get()
  + {static} set()
}

Contracts\Config\Repository <|.. Illuminate\Config\Repository
ArrayAccess <|.. Illuminate\Config\Repository
Illuminate\Config\Repository --> Support\Arr : static call
@enduml
```

> 註：上圖主要表示行為（Contract）與關係（Implement / Static Call），其他細節則忽略。

從這張圖可以知道，`Config\Repository` 提供了數個基本方法如 `has()` `get()` `all()` `set()`，來存取裡面的資訊，同時也提供 [ArrayAccess][] 功能。

`prepend()` 和 `push()` 則是類似 [`array_unshift()`][array_unshift] 和 [`array_push()`][array_push] 的操作，不過是針對裡面的某個 key 的 value 操作。

值得一提的是：它使用了 `Support\Arr` 來操作 array 的 has / get / set。`Support\Arr` 實作了特別的功能，是 key 可以使用 `.` 代表 array 的階層關係，就如同 JavaScript 一樣，舉例如下：

```php
$config = new Config\Repository([
    'foo' => [
        'bar' => [
            'baz' => 'some',
        ],
    ],
]);

$config->get('foo'); // return array('bar' => ['baz' => 'some'])
$config->get('foo.bar'); // return array('baz' => 'some')
$config->get('foo.bar.baz'); // return string 'some'
```

好處是，如果沒有實作這樣的功能時，就得先取得 array 後，再使用 array 操作來取得更底層的元素，這樣就有機會引發 Runtime 的錯誤：

```php
$config = new Config\Repository([
    'foo' => [
        'bar' => [
            'baz' => 'some',
        ],
    ],
]);

$config->get('foo'); // return array('bar' => ['baz' => 'some'])
$config->get('foo')['bar']; // return array('baz' => 'some')
$config->get('foo')['bar']['baz']; // return string 'some'
```

當然也有壞處：key 不能有關鍵字 `.`，因此會發現 Laravel 設定都是使用 `_` 作單字分隔的。

## Laravel 如何使用 Config

Laravel 一開始 [bootstrap][Day02] 載入的 [LoadConfiguration][] 裡，正是在初始化 Config：

```php
public function bootstrap(Application $app)
{
    $items = [];

    // 當 cache 存在的話先載入 cache 的設定 
    if (file_exists($cached = $app->getCachedConfigPath())) {
        $items = require $cached;

        $loadedFromCache = true;
    }

    // 綁定 config 為 Repository 實例
    $app->instance('config', $config = new Repository($items));

    // 如果沒有從 cache 載設定的話，就從檔案裡面載
    if (! isset($loadedFromCache)) {
        $this->loadConfigurationFiles($app, $config);
    }

    // 最後，再把 env 的設定寫回 Application 裡
    $app->detectEnvironment(function () use ($config) {
        return $config->get('app.env', 'production');
    });

    date_default_timezone_set($config->get('app.timezone', 'UTC'));

    mb_internal_encoding('UTF-8');
}
```

而從 `loadConfigurationFiles()` 的程式裡，可以知道設定是從 [`config`](https://github.com/laravel/laravel/tree/v5.7.0/config) 目錄下，載入全部的 `.php` 檔，然後再一一設定回 config 實例裡。只要有遵守設定格式，如：

```php
// myconfig.php

return [
    'foo' => 'bar'
];
```

就能在 Laravel 的執行時期取得這份設定：

```php
config('myconfig.foo') // return string 'bar'
```

這是如何做到的呢？首先要先了解 [`config()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/helpers.php#L271-L282) 做了什麼事，它是 Foundation 的 helper 函式。

```php
function config($key = null, $default = null)
{
    if (is_null($key)) {
        return app('config');
    }

    if (is_array($key)) {
        return app('config')->set($key);
    }

    return app('config')->get($key, $default);
}
```

> `app()` 原始碼可以參考[這裡](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/helpers.php#L113-L120)

從這段程式碼可以了解以下行為：

* `config()` 會從 Container 取得 `config` 物件
* `config(['key' => 'value])` 可以加設定到 `config` 物件
* `config('key')` 是從 `config` 物件取得設定

如此一來，就能簡單的對 Config 物件進行操作。

## 如何替換 Config

上面已經了解 Config 怎麼用了，那想換用別家的，像 [`zend-config`](https://github.com/zendframework/zend-config) 看起來也不錯用，該如何做呢？主要會有兩個重點：實作與初始化

我們知道 Config 它實作了兩個介面，一個是 `Contracts\Config\Repository`，另一個是 `ArrayAccess`。而事實上，整個 Framework 也只依賴這兩個介面。因此，只要實作一個 Adapter 去實作這兩個介面即可取代原有的 Config。

另一個問題是初始化，這就必須調整初始化的過程才行。一種方法是：Laravel 預設的樣版會實作一個 [Kernel](https://github.com/laravel/laravel/blob/v5.7.0/app/Http/Kernel.php#L7) 去繼承 `Foundation\Http\Kernel`，只要在這個類別覆寫 `$bootstrappers` 屬性即可更改初始化過程，如：

```php
protected $bootstrappers = [
    \Illuminate\Foundation\Bootstrap\LoadEnvironmentVariables::class,
    \App\Bootstrap\CustomLoadConfiguration::class,
    \Illuminate\Foundation\Bootstrap\HandleExceptions::class,
    \Illuminate\Foundation\Bootstrap\RegisterFacades::class,
    \Illuminate\Foundation\Bootstrap\RegisterProviders::class,
    \Illuminate\Foundation\Bootstrap\BootProviders::class,
];
```

`CustomLoadConfiguration` 只要實作 `bootstrap(Application $app)` 即可，另外要把 Adapter 物件設定到 Container 的 'config' 下，如：

```php
$app->instance('config', new MyAdapter());
```

另一種方法是，在 [`bootstrap/app.php`](https://github.com/laravel/laravel/blob/v5.7.0/bootstrap/app.php) 綁定實作階段的時候，把自定義的實作綁定到預設的實作上即可，如：

```php
$app->singleton(
    Illuminate\Foundation\Bootstrap\LoadConfiguration::class,
    App\Bootstrap\CustomLoadConfiguration::class
);
```

至於為什麼會成功呢？請再回頭複習一下 [bootstrap 流程][Day02] 與 [Container 分析][Day03]，就會理解了。

## 本日回顧

Config 本身雖然設計很簡單，但 Laravel 使用的方法可不簡單。從 Laravel 如何使用這個物件，可以了解整個流程，與如何安全與簡單地更動流程。

另外，可以思考一件事：Config 本身幾乎涵蓋了整個 Laravel 的生命週期，而 Laravel 本身複雜的流程，應該會影響 Config 的設計，但事實上沒有，反而 Config 任務變得非常單純，單純到可以獨立抽離出來使用。Laravel 如何將複雜的流程配上單純的物件，是很值得大家參考學習的。

[Config]: https://github.com/laravel/framework/tree/v5.7.6/src/Illuminate/Config
[Contracts]: https://github.com/laravel/framework/tree/v5.7.6/src/Illuminate/Contracts
[Support]: https://github.com/laravel/framework/tree/v5.7.6/src/Illuminate/Support
[ArrayAccess]: http://php.net/manual/en/class.arrayaccess.php
[LoadConfiguration]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Bootstrap/LoadConfiguration.php
[array_unshift]: http://php.net/manual/en/function.array-unshift.php
[array_push]: http://php.net/manual/en/function.array-push.php

[Day01]: day01.md
[Day02]: day02.md
[Day03]: day03.md
