---
title: 分析 bootstrap 流程
---

一開始，我們先來了解 Laravel 從 process 開出來後，到進 Controller 前到底做了哪些事。

了解這些會有助於我們理解 Laravel 元件是如何初始化的。

## 從進入點開始

所有 web 程式的進入點（entry point），就是 [`index.php`](https://github.com/laravel/laravel/blob/v5.7.0/public/index.php)。這個檔案主要做的事如下：

```php
$app = require_once __DIR__.'/../bootstrap/app.php';
```

[Application](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Application.php) 是 Laravel 整個生命週期都會使用到的 [Service Container](https://laravel.com/docs/5.7/container)，當需要產生物件的時候，都會需要它的幫忙。

而建構的方法就寫在 [`bootstrap/app.php`](https://github.com/laravel/laravel/blob/v5.7.0/bootstrap/app.php) 裡，主要就做兩件事：*設定主要目錄* 與 *綁定實作*。

```php
$app = new Illuminate\Foundation\Application(
    realpath(__DIR__.'/../')
);

$app->singleton(
    Illuminate\Contracts\Http\Kernel::class,
    App\Http\Kernel::class
);

$app->singleton(
    Illuminate\Contracts\Console\Kernel::class,
    App\Console\Kernel::class
);

$app->singleton(
    Illuminate\Contracts\Debug\ExceptionHandler::class,
    App\Exceptions\Handler::class
);
```

設定主要目錄是因為，後面有很多任務都需要找子目錄，而這些子目錄都相對於主要目錄。而綁定實作後，之後可以依據不同情境，去透過 Application 建置需要的實例來使用。

這是一個很聰明的做法。

現代化的網頁應用，除了提供網頁服務外，有時也會提供 CLI 或是測試等不同使用情境；通常也會希望指令能使用網頁服務的程式碼，或是測試能真正測到實際網頁服務的程式碼。而只要 Application 的初始化一致，即可讓不同情境所使用的程式碼一致。

這個做法同樣可以應用在「Container」與「處理 Http 的角色」是分離的框架上，如：

* Slim Framework 的 [`Slim\Container`](https://github.com/slimphp/Slim/blob/3.x/Slim/Container.php) 與 [`Slim\App`](https://github.com/slimphp/Slim/blob/3.x/Slim/App.php)
* Phalcon 的 `Phalcon\Di` 與 `Phalcon\Mvc\Application`

> 綁定實作之後會在[分析 Container][Day03] 的時候說明細節。

---

拿到 Application 後，繼續 `index.php` 的任務

```php
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
```

Application 第一個生產任務就是 Http Kernel。Http Kernel 正如其名，是處理 Http 的核心。

```php
$response = $kernel->handle(
    $request = Illuminate\Http\Request::capture()
);
```

這裡使用 `handle()` 處理 `Illuminate\Http\Request` 物件。

```php
$response->send();
```

呼叫 `Symfony\Component\HttpFoundation\Response` 的 `send()`，這將會把 response 裡所存放的 header 與 content 輸出到瀏覽器。

在這之前，對 response 所做的任何操作，都只是在記憶體運作，而不會有任何輸出。

```
$kernel->terminate($request, $response);
```

最後呼叫 Http Kernel 的 [`terminate()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Http/Kernel.php#L187-L192)，它其實沒做特別的事，主要是在觸發 terminate 「事件」。它並不是用 Event 實作，而是直接觸發 Middleware 的 `terminate()` 與 Application 的 `terminatingCallbacks` 屬性上。

## Http Kernel 做了些什麼

再來我們肯定會很好奇，那 request 到底是進到什麼樣的黑盒子，才轉成 response 呢？這就要繼續往 Http Kernel 追了。

首先，先看它的[建構子](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Http/Kernel.php#L89-L103)，是在設定一些參數，其中 `Illuminate\Routing\Router` 正是實作 [Routing](https://laravel.com/docs/5.7/routing) 的核心。

關係圖如下：

![](http://www.plantuml.com/plantuml/png/SoWkIImgAStDuVBCoIdDpSnBB4cDSSilpKj9BCdCpulnA2afYF5EBSfBpL7GqjLLG58Lb5zQafcN3gPJYuZGRwEdXwpVEJ-lf2WnkQGOMRrZGK5EPZAOhM2LN9GAL4YgomYRpEMGcfS2z3C0)

PlantUML 原始碼：

```
@startuml
Illuminate\Foundation\Http\Kernel *-- Illuminate\Routing\Router
Illuminate\Foundation\Http\Kernel <.. Illuminate\Contracts\Foundation\Application :create
Illuminate\Foundation\Http\Kernel *-- Illuminate\Contracts\Foundation\Application
@enduml
```

> 類別圖錯字已修正，感謝 Yi-hsuan Lai 提醒。

接著 `handle()` 才是真正做事的地方，也就是剛剛在 `index.php` 看到的那個被呼叫的方法。其中有[一行](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Http/Kernel.php#L116)，是產生 response 的地方：

```php
$response = $this->sendRequestThroughRouter($request);
```

再進去 [`sendRequestThroughRouter()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Http/Kernel.php#L140-L152)，看看它做了什麼事：

```php
// 把 request 設定到 Container
$this->app->instance('request', $request);

// 把綁定 Facade request 的實例清除，這應該是為了測試而做的 
Facade::clearResolvedInstance('request');

// 初始化跟應用程式相關的設定
$this->bootstrap();

// 解析 request 並執行 Controller
return (new Pipeline($this->app))
            ->send($request)
            ->through($this->app->shouldSkipMiddleware() ? [] : $this->middleware)
            ->then($this->dispatchToRouter());
```

如何分配任務給正確的 Controller，將會是 [Routing][] 的任務，這等未來提到的時候再討論。

我們先把焦點先放在 `bootstrap()` 做了什麼吧！

看[原始碼](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Http/Kernel.php#L154-L164)可以發現，首先會判斷如果曾經 bootstrap 過，就不會做事。

這是因為，對傳統 PHP 來說，每次的 request 都會重新建立 process 並重新 bootstrap，但 Laravel 的 Feature 測試是可以在一個測試打多個 request，每次 bootstrap 豈不慢到爆炸，所以才會有這樣的設計。

而 [`bootstrapWith()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Application.php#L199-L210) 是把 [`$bootstrappers`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Http/Kernel.php#L36-L43) 拿來都 bootstrap 一下，內容如下：

```php
\Illuminate\Foundation\Bootstrap\LoadEnvironmentVariables::class,
\Illuminate\Foundation\Bootstrap\LoadConfiguration::class,
\Illuminate\Foundation\Bootstrap\HandleExceptions::class,
\Illuminate\Foundation\Bootstrap\RegisterFacades::class,
\Illuminate\Foundation\Bootstrap\RegisterProviders::class,
\Illuminate\Foundation\Bootstrap\BootProviders::class,
```

從這些 class 名稱，可以大概知道它依續做了這些事：

1. 載入 .env
2. 載入 config 設定
3. 設定 error handle
4. 設定 Facade
5. 註冊 Service Provider
6. 啟動 Service Provider

而從這個順序就可以發現下面這些事

* 在 config 裡可以正常使用 `env()` 拿環境變數，因為 `LoadEnvironmentVariables` 先執行
* Provider 可以正常拿取 `config()` 設定，因為 `LoadConfiguration` 先執行
* Provider 也可以正常使用 Facade，因為 `RegisterFacades` 先執行
* Provider 的 `register()` 會比 `boot()` 先執行
* Provider 炸掉會正確地被 error handler 接到，因為 `HandleExceptions` 先執行

這個順序是定義在 Kernel 的 property，所以意味著它可以被覆寫。比方說我們可能需要使用 YAML 設定檔，則可以加入一個 `\App\Bootstrap\LoadYamlConfiguration::class` 來負責載入 YAML 設定。

## artisan

`index.php` 是 web 的進入點，而 [`artisan`](https://github.com/laravel/laravel/blob/v5.7.0/artisan) 指令則是 cli 的進入點。

內容大同小異，一樣是把 Application 建構好後，再換拿 Console Kernel。跟 Http Kernel 一樣，會有一個 `handle()` 方法在處理所有事情，不過對 console 而言，需要的參數是 I/O。最後一樣也有 `terminate()`，不一樣的是多了 `exit($status)`，這是因為對 cli 來說，一個指令的結束，會需要回傳一個狀態碼，而這任務是由 `exit()` function 達成。

[`handle()`](https://github.com/laravel/framework/blob/5.7/src/Illuminate/Foundation/Console/Kernel.php#L117-L138) 實作很簡單：bootstrap、getArtisan、run。其中 Artisan 比較複雜，未來有機會再來討論。

[`bootstrap`()](https://github.com/laravel/framework/blob/5.7/src/Illuminate/Foundation/Console/Kernel.php#L294-L307) 實作比 Http Kernel 多了幾件事：

```php
$this->app->loadDeferredProviders();

if (! $this->commandsLoaded) {
    $this->commands();

    $this->commandsLoaded = true;
}
```

Application 的 `loadDeferredProviders()` 方法是把原本要延遲載入的 provider 一次性的全載進來。

`commands()` 則是用在 [Closure commands](https://laravel.com/docs/5.7/artisan#closure-commands) 上，因為官方說明是使用 Artisan facade 來註冊 Closure commands。對 Kernel 來說，只要 Artisan 的生命週期還在，這邊就不需要再次呼叫 `commands()`，所以就出現類似 `hasBeenBootstrapped()` 的判斷寫法。

## 今日總結

以上，是 Laravel 在進到商業邏輯層（Controller / Command）前的程式碼分析，同時也描述了一小部分的 lifecycle。

了解之後，接下來在看某幾個跟流程初始化有關的元件，就會比較好理解為何它能正常運作。同時，也可以知道 Laravel 如何做到調整初始化流程，與了解它彈性的設計。

[Day03]: day03.md
