---
title: 分析 Application
---

Application 繼承了 [Container][Day03]，同時也是整個 Laravel 生命週期會用到的共同容器。而 Laravel 為了做到元件可獨立使用，所以大部分的元件，為了要取得其他相依元件，都會只依賴 Container。

因此 Application 必須要遵守[里氏替換原則][Refactoring Day09]，才不會有意外發生。

可以翻了一下原始碼，有下列方法被覆寫：

```php
public function bound($abstract)
{
    // 如果 `deferredServices` 存在，或是呼叫原本 Container::bound() 是 true 的話，就回傳 true
    return isset($this->deferredServices[$abstract]) || parent::bound($abstract);
}

public function make($abstract, array $parameters = [])
{
    $abstract = $this->getAlias($abstract);

    // 如果 `deferredServices` 存在，但 `instance` 裡面沒有時，就載入 DeferredProvider
    if (isset($this->deferredServices[$abstract]) && ! isset($this->instances[$abstract])) {
        $this->loadDeferredProvider($abstract);
    }

    return parent::make($abstract, $parameters);
}

public function flush()
{
    parent::flush();

    // Application 多了這些屬性要清空
    $this->buildStack = [];
    $this->loadedProviders = [];
    $this->bootedCallbacks = [];
    $this->bootingCallbacks = [];
    $this->deferredServices = [];
    $this->reboundCallbacks = [];
    $this->serviceProviders = [];
    $this->resolvingCallbacks = [];
    $this->afterResolvingCallbacks = [];
    $this->globalResolvingCallbacks = [];
}
```

可以思考一下這些方法被覆寫時，是如何避免破壞原有的行為。比方說，要覆寫改變物件狀態的方法，通常都會有明確呼叫父類別的方法（`parent::method()`）來確保原有的行為依然會被執行。像 `flush()` 就很好理解，它先把原本 Container 的狀態清除，再把 Application 的狀態清除。

## 建構子

與 Container 不同，Application 是有建構子的：

```php
public function __construct($basePath = null)
{
    // 設定 Application 相關路徑
    if ($basePath) {
        $this->setBasePath($basePath);
    }

    // 註冊預設的實例
    $this->registerBaseBindings();

    // 註冊預設的 service provider
    $this->registerBaseServiceProviders();

    // 註冊預設的別名
    $this->registerCoreContainerAliases();
}
```

其中特別提一下預設的 service provider，也就是一開始 Application 會準備好哪些 service。

```php
protected function registerBaseServiceProviders()
{
    $this->register(new EventServiceProvider($this));

    $this->register(new LogServiceProvider($this));

    $this->register(new RoutingServiceProvider($this));
}
```

所以這幾個 service provider 沒在 [`config/app.php`](https://github.com/laravel/laravel/blob/v5.7.0/config/app.php#L127-L148) 裡面出現，但莫名奇妙的它們能 work 的原因就在這裡。

## Register Service Provider

[`register()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Application.php#L558-L600) 的註冊邏輯分析如下：

```php
public function register($provider, $force = false)
{
    // 如果已註冊過，且沒要強制重新註冊的話，就會回傳 service provider 的實例
    if (($registered = $this->getProvider($provider)) && ! $force) {
        return $registered;
    }

    // 如果是字串的話，會把建構它，同時傳入 app 實例。
    // P.S. 筆者覺得奇妙的是，怎麼不是使用 make() 來產生實例
    if (is_string($provider)) {
        $provider = $this->resolveProvider($provider);
    }

    // 當 register method 存在時，就呼叫它。這用法在 Laravel 很常見，也確實非常好用。
    if (method_exists($provider, 'register')) {
        $provider->register();
    }

    // 如果有 property `bindings`，就拿來跑 bind()
    if (property_exists($provider, 'bindings')) {
        foreach ($provider->bindings as $key => $value) {
            $this->bind($key, $value);
        }
    }

    // 如果有 property `singletons`，就拿來跑 singleton()
    if (property_exists($provider, 'singletons')) {
        foreach ($provider->singletons as $key => $value) {
            $this->singleton($key, $value);
        }
    }

    // 標記為已註冊，也就是一開始判斷是否已註冊的依據
    $this->markAsRegistered($provider);

    // 系統已 boot 的話，就呼叫 service provider 的 boot() 
    if ($this->booted) {
        $this->bootProvider($provider);
    }

    return $provider;
}
```

> 上面這些功能，其實在[文件](https://laravel.com/docs/5.7/providers#the-register-method)裡面都有出現。

`register()` 邏輯是比較單純的，複雜的其實是從 [bootstrap 流程][Day02]如何進到這裡。第二天曾提到，`bootstrapWith()` 載了很多 bootstrappers，其中有一個是 `RegisterProviders`，這正是註冊所有 service provider 的起始點。

```php
public function bootstrap(Application $app)
{
    $app->registerConfiguredProviders();
}
```  

而它其實把註冊邏輯全寫到 `Application::registerConfiguredProviders()` 了，這裡就不是很好理解了。

```php
$providers = Collection::make($this->config['app.providers'])
                ->partition(function ($provider) {
                    return Str::startsWith($provider, 'Illuminate\\');
                });
```

首先把 config/app.php 裡面的 providers 拆成兩組 array：Illuminate 自家的和開發者自己寫在設定的。

```php
$providers->splice(1, 0, [$this->make(PackageManifest::class)->providers()]);
```

[`PackageManifest`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/PackageManifest.php) 是 Laravel 5.5 推出的新功能－－[Package Discovery][] 的實作。

接著把 `PackageManifest` 所解析出來的 providers 插入在中間，排序就會變成：

1.  Illuminate
2.  PackageManifest
3.  Custom

```php
(new ProviderRepository($this, new Filesystem, $this->getCachedServicesPath()))
            ->load($providers->collapse()->toArray());
```

最後使用　`ProviderRepository::load()` 來將所有 provider 都載入。我們來看看裡面做些什麼，因為裡面有 Application 的另外一個重要功能。

```php
public function load(array $providers)
{
    // 載入 manifest，剛程式看到其實它是 bootstrap/cache/services.php 這個檔案
    $manifest = $this->loadManifest();

    // 接著看 minifest 是不是要重新產生新的。當第一次跑，或是 provider 資訊不同時，就會重新產生
    if ($this->shouldRecompile($manifest, $providers)) {
        $manifest = $this->compileManifest($providers);
    }

    // 如果有 event trigger 載入的話，就註冊事件
    foreach ($manifest['when'] as $provider => $events) {
        $this->registerLoadEvents($provider, $events);
    }

    // 如果有需要立馬載入的 provider，就立馬呼叫 register
    foreach ($manifest['eager'] as $provider) {
        $this->app->register($provider);
    }

    // 最後再把 deferred service 設定回 Application
    $this->app->addDeferredServices($manifest['deferred']);
}
```

是的，Application 另外一個重要的功能就是 lazy loading，這也是原本的 Container 沒有的。

再來看一下 `compileManifest()` 到底幫我們產生什麼樣的資料：

```php
protected function compileManifest($providers)
{
    // 首先用已知的 provider 產生一個乾淨的 manifest
    $manifest = $this->freshManifest($providers);

    foreach ($providers as $provider) {
        // 產生 provider，實作與 Application::resolveProvider() 一模一樣
        $instance = $this->createProvider($provider);

        // 如果是 deferred provider 就把 deferred service 對應 provider 的記錄寫入 manifest 裡
        if ($instance->isDeferred()) {
            foreach ($instance->provides() as $service) {
                $manifest['deferred'][$service] = $provider;
            }

            // 如果有設定 events trigger 載入的話，同時也寫入 when。
            $manifest['when'][$provider] = $instance->when();
        }

        // 如果不是 deferrd service 就列入立馬載入的列表
        else {
            $manifest['eager'][] = $provider;
        }
    }
    
    // 最後寫入檔案
    return $this->writeManifest($manifest);
}
```

從追這些程式的過程，有發現 `when()` 的使用方法，但[文件](https://laravel.com/docs/5.7/providers)其實是沒有寫的。筆者推測，可能官方還在思考要用類似 `boot()` 宣告方法好還是像 `bindings` 宣告屬性好。

不過應該還是會用宣告方法的方式，因為即使是 deferred provider，在 register provider 時期，很多情況還是直接 new 實例會比較保險，用 `Application::make()` 找不到依賴實例的機率還是比較高的。

## 今日總結

分析完 Container 與 Application 的程式碼，就可以了解 Laravel 是如何輕鬆產生實例，以及註冊 service provider 的原理等。大部分的元件都會使用到 Container，之後分析其他元件就會比較好理解了。

[Package Discovery]: https://laravel.com/docs/5.5/releases#laravel-5.5
[Application]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Application.php

[Refactoring Day09]: /src/ironman-refactoring-30-days/day09.md

[Day02]: day02.md
[Day03]: day03.md
