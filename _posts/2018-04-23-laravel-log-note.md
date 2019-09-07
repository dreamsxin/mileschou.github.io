---
layout: post
title: Laravel Log 的小筆記
---

Laravel 的 Log 包的很簡單用，但想做更客製化的功能該怎麼辦？

> Laravel <= 5.5 適用

如果需要自定義 monolog 其實很簡單，只要在 provider 的 boot() 階段執行下面程式碼即可：

```php
public function boot()
{
    $this->app->configureMonologUsing(function($monolog) {
        // 想要我的設定嗎？在這邊都給你！
        return $monolog;
    });

    // 這裡即可拿到客制的 Monolog
    Log::getMonolog();
}
```

## Laravel 5.6 呢？

5.6 開始， Laravel 換依賴 [PSR-3][] 的 LoggerInterface ，也就是可以替換成其他 Logger 實作。但我們還是可以把 Monolog 的物件拿出來操作：

```php
public function boot()
{
    $monolog = Log::getLogger();
    // 設定 monolog ...
}
```

或是直接把 Facade 當作 Monolog 來用（因為背後的 [`Illuminate\Log\Logger`][Logger] 有實作 `__call()` ）：

```php
public function boot()
{
    Log::pushHandler(new Handler());
}
```

[Logger]: https://github.com/laravel/framework/blob/5.6/src/Illuminate/Log/Logger.php
[PSR-3]: https://www.php-fig.org/psr/psr-3/
