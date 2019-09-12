---
title: 分析 Log
---

Laravel 的 [Log][] 套件在 5.5 版之前，是使用 [Writer][] 包裝 [Monolog][]，成為一個 proxy pattern，被代理的類別則是寫死 Monolog。在 5.6 版開始，設計改採用 [Logger][] 包裝 PSR-3 的 [LoggerInterface][]，一樣是 proxy pattern，但被代理的類別只要是符合 PSR-3 的介面，就能使用。

> 後面一樣只會討論 5.7.6 版的原始碼。

Service provider 定義非常簡單，就直接初始化 `LogManager`：

```php
$this->app->singleton('log', function () {
    return new LogManager($this->app);
});
```

LogManager 實作了 LoggerInterface。它跟之前提到的 [Day10][] 有異區同工之妙，方法定義也非常接近，只差 LogManager 並沒有繼承 Manager 而已。

只要 [logging.php](https://github.com/laravel/laravel/blob/v5.7.0/config/logging.php) 有設定好，基本上就可以直接 make 出來用：

```php
app()->make('log')->info('something');
```

來看看 `info()` 裡面的實作：

```php
public function info($message, array $context = [])
{
    return $this->driver()->info($message, $context);
}
```

非常簡單，取得 LoggerInterface driver 後，馬上再把 log 資訊轉交給 driver。這也是為何會說它是 proxy pattern 的主因－－因為 LogManager 本身並沒有做跟 log 有關的事。

接著，看看 `driver()` 做了哪些事才能取得實例：

```php
public function driver($driver = null)
{
    return $this->get($driver ?? $this->getDefaultDriver());
}
```

`getDefaultDriver()` 是從 `logging.php` 裡取得設定，檔案註解裡有提到有下列幾種 driver：

* single 
* daily
* slack
* syslog
* errorlog
* monolog
* custom
* stack

我們接著來看 single 與 stack 兩種 driver 怎麼透過 `get()` 產生吧：

```php
protected function get($name)
{
    try {
        // 當還沒有產 driver 實例的話，就解析同時設定 driver
        return $this->channels[$name] ?? with($this->resolve($name), function ($logger) use ($name) {
            return $this->channels[$name] = $this->tap($name, new Logger($logger, $this->app['events']));
        });
    } catch (Throwable $e) {
        // 當產 log 實例有錯的話，就改使用預設的 logger，層級會是最嚴重的 emergency
        return tap($this->createEmergencyLogger(), function ($logger) use ($e) {
            $logger->emergency('Unable to create configured logger. Using emergency logger.', [
                'exception' => $e,
            ]);
        });
    }
}
```

> 這裡的 channels 指的是屬於 LogManager 的 channel，與 Monolog 無關。

`with()` 函式的等價程式碼如下：

```php
$callable = function ($logger) {
    // ...
}

return $callbale($this->resolve($name));
```

Laravel 會有這些簡單的函式，最主要的用途是為了 function chain。比方說 `with()->blah();` 就有辦法實現。

不過事實上，PHP 7.0 開始也支援下面的寫法，也是可以參考的：

```php
return (function($logger) {
    // ...
})($this->resolve($name));
```

產生實例後，會使用 `tap()` 方法（跟之前提到的 `tap()` 函式是不同的）設定實例。

```php
protected function tap($name, Logger $logger)
{
    // 看看 driver 設定裡的 tap 有什麼
    foreach ($this->configurationFor($name)['tap'] ?? [] as $tap) {
        // 有的話就解析出來
        list($class, $arguments) = $this->parseTap($tap);

        // 接著會建 tap class 實例，並傳入 logger，並把參數用 , 拆分傳入 
        $this->app->make($class)->__invoke($logger, ...explode(',', $arguments));
    }

    return $logger;
}

protected function parseTap($tap)
{
    // 如果有 : 的話，就以它為分界拆成兩個字串
    return Str::contains($tap, ':') ? explode(':', $tap, 2) : [$tap, ''];
}
```

從以上原始碼可以得知，tap 設定與 middleware 設定有點雷同，如：

```php
class SomeTap
{
    public function __invoke($logger, $param1, $param2)
    {
    }
}

// config

[
    'tap' => SomeTap::class . ':arg1,arg2',
];
```

簡單來說，這是一種用類別 `__invoke()` 來取代 `tap()` 功能的另解法。

`tap()` 裡面基本上是對 `$logger` 做一些初始化設定，比方說 Monolog 設定 `processor` 等。

再回頭過來看 `resolve()` 如何做：

```php
protected function resolve($name)
{
    // 取得設定
    $config = $this->configurationFor($name);

    // 沒設定就炸給它看
    if (is_null($config)) {
        throw new InvalidArgumentException("Log [{$name}] is not defined.");
    }

    // 如果有自定義的產生方法的話就用
    if (isset($this->customCreators[$config['driver']])) {
        return $this->callCustomCreator($config);
    }

    // 沒有自定義方法的話，則使用預設建置方法
    $driverMethod = 'create'.ucfirst($config['driver']).'Driver';

    if (method_exists($this, $driverMethod)) {
        return $this->{$driverMethod}($config);
    }

    throw new InvalidArgumentException("Driver [{$config['driver']}] is not supported.");
}
```

從上面的程式碼來看，single 與 stack 會對應到的建置方法為：

* createSingleDriver
* createStackDriver

```php
protected function createSingleDriver(array $config)
{
    // 從 $config 設定中，找出要設定給 monolog 的 channel 名稱
    return new Monolog($this->parseChannel($config), [
        // 建置 Handler
        $this->prepareHandler(
            new StreamHandler(
                $config['path'], $this->level($config),
                $config['bubble'] ?? true, $config['permission'] ?? null, $config['locking'] ?? false
            )
        ),
    ]);
}

protected function createStackDriver(array $config)
{
    // 取得所有 channel 的 handler 
    $handlers = collect($config['channels'])->flatMap(function ($channel) {
        return $this->channel($channel)->getHandlers();
    })->all();

    // 再重新建置一個包含所有 handler 的 Monolog 實例
    return new Monolog($this->parseChannel($config), $handlers);
}
```

Stack 本身代表的意義是把所有 Laravel Logger 所定義的 channels（也就是 driver）整合成一個懶人包，只要對 stack 推送 log，所有在設定裡的 channel 都會跟著推送 log。

如果想針對單一 driver 推 log 也很簡單，使用 `driver()` 取得對應的 driver 即可。

雖然 Monolog 已經有內建 [Registry][]，是類似概念的做法，但比起 Laravel 的 LogManager 還是缺了少了幾個元素，一個是設定轉成建實例的方法；另一個則是單元測試的易用性。

談到測試，Laravel 還是大勝許多套件，剩下沒幾天時間，希望有機會能談到測試。

[Log]: https://github.com/laravel/framework/tree/v5.7.6/src/Illuminate/Log
[Logger]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Log/Logger.php
[LoggerInterface]: https://github.com/php-fig/log/blob/master/Psr/Log/LoggerInterface.php
[Writer]: https://github.com/laravel/framework/blob/5.5/src/Illuminate/Log/Writer.php
[Registry]: https://github.com/Seldaek/monolog/blob/master/src/Monolog/Registry.php

[Monolog]: /src/ironman-decompose-wheelseels/day12.md

[Day10]: day10.md
