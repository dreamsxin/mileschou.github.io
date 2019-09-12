---
title: 分析 Container（1）
---

昨天有提到 [Application][] 是 Laravel [Service Container][] 的實作，它繼承了 [Container][]，是負責管理元件如何產生的元件。比方說：

```php
$container = new Container();

$container->singleton(MyClass::class, function () {
    return new MyClass('dep');
});
```

如此一來，當使用 `make()` 時，它就會觸發 callback，依照 callback 的寫法來產生對應的物件

```php
$instance1 = $container->make(MyClass::class); // return instance of MyClass

$instance2 = $container->make(MyClass::class); // return the same instance, because it's singleton
```

事實上，它最好用的地方，正是自動處理依賴注入的功能：

```php
class Dep
{
}

class MyClass
{
    public function __construct(Dep $dep)
    {
        // ...
    }
}

$container = new Container();

$container->make(MyClass::class); // 這是 Work 的
```

為什麼會這麼神奇呢？讓我們一起看看原始碼吧！

## 類別圖

首先，依賴很單純，它只依賴 [Contracts][] 並實作 [ArrayAccess][]：

![](http://www.plantuml.com/plantuml/png/fLDDazCm3BtdL_YGG_de_W06cDtkgGTc6Ax0GRMLnBEApLWoiBFqlwDD2TlW98NXuhZIqtloKtND0aboJvKFWga1Y-Ozfq-tCGZuW6Ut_M_0GsNC2_C01vO4LewcHTdKtZtxCzu1d-B7wenV6OSypwcKv8UOWzlKOw0G0VB0J_cNfXuY1KwWVKAnmZGmYsfHvVHRv0u-k8cGZS4c53HlJCX46k4E4ZhztG0npZBic__ZO1zQGebXZQQemk-2q-vlAN9EgAN3fHJoWGM2nOdE62pGtpeCcx6DCjte6TFzoXnxk9j8GKfmR-elaA1NniJwj8-VYp8BHAghvm7itLAPTkwmWKpo3gMBRiccX1pfAnR_jmAYGvWrSsnaIG0QmVJXtoXqUom1izaJvTu743nRdTtZVfnUDIuF2uYtlxmPwY_kzEiVs-twPbQhMIMukYeRd3BSFCxcnbfa_YlyUjfijsylM_BAdDmOpBZ4-5nDM8Je2cMWdGzE9xVBdfosU8t1vPv-0W00)

PlantUML 原始碼如下：

```
@startuml
interface Psr\Container\ContainerInterface {
  + {abstract} get($id)
  + {abstract} has($id)
}

interface Contracts\Container\Container {
  + {abstract} bound($abstract)
  + {abstract} alias($abstract, $alias)
  + {abstract} tag($abstracts, $tags)
  + {abstract} tagged($tag)
  + {abstract} bind($abstract, $concrete = null, $shared = false)
  + {abstract} bindIf($abstract, $concrete = null, $shared = false)
  + {abstract} singleton($abstract, $concrete = null)
  + {abstract} extend($abstract, Closure $closure)
  + {abstract} instance($abstract, $instance)
  + {abstract} when($concrete)
  + {abstract} factory($abstract)
  + {abstract} make($abstract, array $parameters = [])
  + {abstract} call($callback, array $parameters = [], $defaultMethod = null)
  + {abstract} resolved($abstract)
  + {abstract} resolving($abstract, Closure $callback = null)
  + {abstract} afterResolving($abstract, Closure $callback = null)
}

class Illuminate\Container\BoundMethod {
  + {static} call()
}

Psr\Container\ContainerInterface <|-- Contracts\Container\Container
Contracts\Container\Container <|.. Illuminate\Container\Container
ArrayAccess <|.. Illuminate\Container\Container
Illuminate\Container\Container --> Illuminate\Container\BoundMethod : static call
Illuminate\Container\Container *-- Illuminate\Container\ContextualBindingBuilder
@enduml
```

從類別圖可以了解：

* 核心角色為 `Illuminate\Container\Container`（下稱 `Container`）
* `Illuminate\Container\BoundMethod`（下稱 `BoundMethod`）為類似 helper 的輔助角色
* `Illuminate\Container\ContextualBindingBuilder`（下稱 `ContextualBindingBuilder`）也是輔助角色，協助產生 container 的設定。

## `singleton()` 做了什麼事

從一開始的範例，我們知道 `singleton()` 是設定 callback 表示該物件如何建置，而 `make()` 則是產生。首先看 [`singleton()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Container/Container.php#L345-L348) 的實作是什麼：

```php
public function singleton($abstract, $concrete = null)
{
    $this->bind($abstract, $concrete, true);
}
```

這裡可以了解，它是 `bind()` 的另一種呼叫方法，因為 PHP 並不像 Java 有多型，所以常會使用這一類的寫法增加可用性與可閱讀性。如：

```php
public function getData(array $query)
{
    // ...
}

public function getDataById($id)
{
    $this->>getData([
        'id' => $id,
    ]);
}
```

而 [`bind()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Container/Container.php#L214-L240) 的原始碼如下，雖然已經有清楚的註解了，不過還是簡單用中文描述：

```php
public function bind($abstract, $concrete = null, $shared = false)
{
    // 先把舊的實例丟掉，從這個方法的實作可以得知，跟實例有關係的屬性是 instances 和 aliases
    $this->dropStaleInstances($abstract);

    // 當沒有給 concrete 的話，則會把 abstract 當 concrete 來處理
    if (is_null($concrete)) {
        $concrete = $abstract;
    }

    // 當 concrete 不是 Closure 的話，會預期它是 class 名稱，Laravel 會把它包裝成預設的 Closure
    if (! $concrete instanceof Closure) {
        $concrete = $this->getClosure($abstract, $concrete);
    }

    // 屬性 `bindings` 會放綁定相關資訊
    $this->bindings[$abstract] = compact('concrete', 'shared');

    // 當 abstract 已被解析過的話，會觸發 rebound 事件，跟 resolved 相關的屬性是 resolved 與 instances
    if ($this->resolved($abstract)) {
        $this->rebound($abstract);
    }
}
```

> 在追程式碼的過程中，會同時注意屬性有哪些，因為不同方法之間的關聯，是由屬性連繫起來的。

其中，我們需要先了解預設的 [Closure](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Container/Container.php#L249-L258) 是什麼：

```php
protected function getClosure($abstract, $concrete)
{
    return function ($container, $parameters = []) use ($abstract, $concrete) {
        if ($abstract == $concrete) {
            return $container->build($concrete);
        }
        return $container->make($concrete, $parameters);
    };
}
```

這裡的 `$container`，指的就是 `$this`。剛剛 `bind()` 裡面有提到：

> 當沒有給 concrete 的話，則會把 abstract 當 concrete 來處理

這裡原始碼可以發現，如果上述情況的話，它會使用 `build()` 建置實例；不是的話，則會使用一開始提到的 `make()` 建置。

這兩個之間的差異，只要繼續看 `make()` 就會了解。

## `make()` 做了什麼事

[`make()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Container/Container.php#L599-L602) 跟 `singleton()` 類似，也是在呼叫另一個方法 `resolve()`，不過這個做法會比較像是 proxy pattern。

```php
public function make($abstract, array $parameters = [])
{
    return $this->resolve($abstract, $parameters);
}
```

[`resolve()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Container/Container.php#L623-L675) 可就複雜了：

```php
protected function resolve($abstract, $parameters = [])
{
    // 取得抽象的別名，這是從屬性 `aliases` 取得的
    $abstract = $this->getAlias($abstract);

    // 確定是否需要用 ContextualBuild
    $needsContextualBuild = ! empty($parameters) || ! is_null(
        $this->getContextualConcrete($abstract)
    );

    // 這裡是 singleton 實作的一部分，所以同時也可以知道屬性 `instances` 是用來實作 registry singleton pattern 的 
    if (isset($this->instances[$abstract]) && ! $needsContextualBuild) {
        return $this->instances[$abstract];
    }

    // 屬性 `with` 是用拿暫存的，後面產生實例的過程會用到 parameters，將會從 with 取得
    $this->with[] = $parameters;

    // 這裡會嘗試由 abstract 取得 concrete，真的都找不到的話，將會回傳 abstract
    $concrete = $this->getConcrete($abstract);

    // 產生實例
    if ($this->isBuildable($concrete, $abstract)) {
        $object = $this->build($concrete);
    } else {
        $object = $this->make($concrete);
    }

    // 如果有定義 extender 就跑一下，它可以幫原本的物件定義做一些改變或裝飾，類似 decorator pattern
    foreach ($this->getExtenders($abstract) as $extender) {
        $object = $extender($object, $this);
    }

    // 如果是 singleton 的話，會把實例存在屬性 `instances` 裡，也就是剛剛上面看到的 registry singleton pattern 會使用到
    if ($this->isShared($abstract) && ! $needsContextualBuild) {
        $this->instances[$abstract] = $object;
    }

    // 觸發解析事件，類似 observer pattern
    $this->fireResolvingCallbacks($abstract, $object);

    // 標記這個物件已被解析過
    $this->resolved[$abstract] = true;

    // 把剛剛暫存的 parameters 資料移除
    array_pop($this->with);

    return $object;
}
```

整個過程可大略分成下面幾個重點：

* `make()` or `build()`
* Registry singleton pattern
* Extenders（或 decorator pattern）
* Fire callback（或 observer pattern）

後面三個有設計模式可以參考，都很好理解它們的目的甚至實作；建置如果使用 `make()` 的話，就會發生遞迴呼叫（recursive call），因此要先了解 [`isBuildable()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Container/Container.php#L745-L748) 實作，先知道什麼情況會發生遞迴呼叫，什麼情況會終止。

```php
protected function isBuildable($concrete, $abstract)
{
    return $concrete === $abstract || $concrete instanceof Closure;
}
```

實作非常簡單：如果 abstract 與 concrete 相同，或是 concrete 是 Closure 的話，會使用 `build()`；反之，兩個不同，而且 concrete 不是 Closure 時，則會使用 `make()`。

回顧上面 `bind()` 曾提到的：

> 當 concrete 不是 Closure 的話，會預期它是 class 名稱，Laravel 會把它包裝成預設的 Closure

換句話說，只要曾使用 `bind()` 定義過的類別，就一定會使用 `build()`，舉幾個[官網的例子](https://laravel.com/docs/5.7/container)：

```php
$this->app->bind('HelpSpot\API', function ($app) {
    return new HelpSpot\API($app->make('HttpClient'));
});
```

這個情況因為 concrete 是 Closure，所以會使用 `build()`。再看另一個例子：

```php
$this->app->bind(
    'App\Contracts\EventPusher',
    'App\Services\RedisEventPusher'
);
```

因為 concrete 不是 Closure，它會包裝成預設的 Closure 存起來，所以最後也會使用 `build()`。

如果沒有綁定過的類別拿來 `make()` 呢？比方說一開始舉的例子：

```php
$container->make(MyClass::class);
```

這時就得了解 concrete 的來源：[`getConcrete()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Container/Container.php#L683-L697) 的實作了：

```php
protected function getConcrete($abstract)
{
    // 看看 contextual binding 有沒有對應的設定，有的話就回傳
    if (! is_null($concrete = $this->getContextualConcrete($abstract))) {
        return $concrete;
    }

    // 屬性 `bindings` 只有 bind() 才會 assign，因此它必定為 Closure，而流程會走 build()
    if (isset($this->bindings[$abstract])) {
        return $this->bindings[$abstract]['concrete'];
    }

    // 如果都不是，就回傳 abstract，流程也會走 build()
    return $abstract;
}
```

看起來關鍵就是 [`getContextualConcrete()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Container/Container.php#L705-L723) 做了什麼事了：

```php
protected function getContextualConcrete($abstract)
{
    // 先找看看有沒有 contextual binding
    if (! is_null($binding = $this->findInContextualBindings($abstract))) {
        return $binding;
    }

    // alias 也沒搞頭的話，就回傳 null
    if (empty($this->abstractAliases[$abstract])) {
        return;
    }

    // 有的話，就都找看看有沒有 contextual binding 
    foreach ($this->abstractAliases[$abstract] as $alias) {
        if (! is_null($binding = $this->findInContextualBindings($alias))) {
            return $binding;
        }
    }
}
```

[Contextual Binding][] 是用在同一個類別，在不同地方會使用到不同的實例，這裡再講下去會太複雜，就先跳過。

從以上追過原始碼的結果會發現，除非是使用 Contextual Binding，它才會在 `resolve()` 的時候使用 `make()`，其他都會使用 `build()`。

今天先到此結束，明天再繼續看 `build()` 做了什麼。

[Application]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Application.php
[ArrayAccess]: http://php.net/manual/en/class.arrayaccess.php
[Contracts]: https://github.com/laravel/framework/tree/v5.7.6/src/Illuminate/Contracts
[Contextual Binding]: https://laravel.com/docs/5.7/container#contextual-binding
[Service Container]: https://laravel.com/docs/5.7/container
[Container]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Container/Container.php
