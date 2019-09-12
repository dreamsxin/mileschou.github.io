---
title: 分析 Session（1）
---

今天要講的是與預設 middleware 相關的另一個元件－－[Session][]。這個元件應該是到目前為止，最多類別的元件。

在看類別圖之前，我們先從 [`SessionServiceProvider`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Session/SessionServiceProvider.php) 了解裡面有哪些相關的類別需要初始化：

> 原本是分不同的方法各別呼叫 singleton，這裡刻意使用依序呼叫的方法來呈現。

```php
$this->app->singleton('session', function ($app) {
    return new SessionManager($app);
});

$this->app->singleton('session.store', function ($app) {
    return $app->make('session')->driver();
});

$this->app->singleton(StartSession::class);
```

從這裡可以知道，[`SessionManager`][] 是最主要的核心類別，[`StartSession`][] 則是 middleware。

## 類別圖

為了版面簡潔，`Illuminate\Session` 開頭的類別，都有忽略。除非是跟其他元件有關聯。另外為了表示這元件的內聚關係，有忽略一些靜態呼叫的類別，如 `Illuminate\Support\Arr` 類別。

![](http://www.plantuml.com/plantuml/png/bP9FJm913CNlyocQU7Nu0CGG8chae0UvxgNi5fWuT3PjLqB4xwwoJ1337_Qqa-Rz-jg-7QgXMBEC3gTgWgL16L4LnZ4soy1eL4oQkavYnGiopadWqm7SG2NXWqIX3oY2wrkOM1A2m6h89Ralvm8RoGnBWWcfXiJFo5Ka6UVwNl7NRvHuEuaM8omNLBnHdJHOalKb_IENigxjnoa_IIunkz7orxapczzjVAIP-RpFhduEITwtbt7jVNeIvWlhRGRNJPFNg5hQRmQvsy44uFq0_cdxmBJAUHm5ZkhQOlB-P6XxdopjaCOsqdjKgWxRGw-fVwzoolGabtoLLkol_856ARq7wcRzW8PJr8xKKuWTYTScncx4aBXgbl4R)

```
@startuml
abstract class Illuminate\Support\Manager {
  # drivers : array, Store instance
}

interface SessionHandlerInterface
interface Illuminate\Contracts\Cache\Repository
interface Illuminate\Contracts\Encryption\Encrypter
interface Illuminate\Contracts\Session\Session

Illuminate\Support\Manager <|-left- SessionManager
Illuminate\Support\Manager o-- Store
Store .right.|> Illuminate\Contracts\Session\Session
EncryptedStore -|> Store
SessionManager --> EncryptedStore : new instance
SessionManager --> Store : new instance
Store o-- SessionHandlerInterface
EncryptedStore o-- Illuminate\Contracts\Encryption\Encrypter
CacheBasedSessionHandler .up.|> SessionHandlerInterface
CacheBasedSessionHandler o-down- Illuminate\Contracts\Cache\Repository
CookieSessionHandler .up.|> SessionHandlerInterface
DatabaseSessionHandler .up.|> SessionHandlerInterface
FileSessionHandler .up.|> SessionHandlerInterface
NullSessionHandler .up.|> SessionHandlerInterface
@enduml
```

從這張圖可以了解類別間關係，比方說：

* [`SessionManager`][] 是管理 driver 的實作，它繼承了 `Illuminate\Support\Manager`
* [`Illuminate\Contracts\Session\Session`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Contracts/Session/Session.php) 是管資料存放在記憶體的介面
* [`SessionHandlerInterface`](http://php.net/manual/en/class.sessionhandlerinterface.php) 是管資料存放在持久化空間的介面
* [`CacheBasedSessionHandler`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Session/CacheBasedSessionHandler.php) 可以接多種實作，只要符合 [`Illuminate\Contracts\Cache\Repository`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Contracts/Cache/Repository.php)

## SessionManager

雖然有很多關係連結，不過就先從 SessionManager 類別開始吧！SessionManager 繼承了 [`Illuminate\Support\Manager`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Support/Manager.php)。

Manager 的用途很特別，通常我們在不同的場景會使用不同實作時，如 DB 在測試會使用 SQLite，上線會使用 MySQL，這時為符合 open-closed principle，通常我們會選擇 strategy pattern。Manager 就是一個管理 strategy 實例的抽象類。

一開始初始化，當然會需要 Container，因為後面要產生實例的時候會需要它。而今天一開始在講 service provider 時，有看到這段程式碼：

```php
$this->app->singleton('session.store', function ($app) {
    return $app->make('session')->driver();
});
```

這是取得實例的實作，來看看 [`Manager::driver()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Support/Manager.php#L57-L75)：

```php
public function driver($driver = null)
{
    // 如果是 null 就使用預設的 driver
    $driver = $driver ?: $this->getDefaultDriver();

    // 如果 default 是 null ....別鬧了！
    if (is_null($driver)) {
        throw new InvalidArgumentException(sprintf(
            'Unable to resolve NULL driver for [%s].', static::class
        ));
    }

    // 如果還沒建構的話，就建構起來。這裡使用了 registry of singleton pattern 來實作單例 
    if (! isset($this->drivers[$driver])) {
        $this->drivers[$driver] = $this->createDriver($driver);
    }

    return $this->drivers[$driver];
}
```

從這段程式碼和 `session.store` 的建構方法可以知道，SessionManager 只會使用 default driver 而已（也就是 `$driver` 恆為 null）。Manager 定義 [`getDefaultDriver()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Session/SessionManager.php#L200-L203) 是抽象方法，我們先來看 SessionManager 是如何實作的：

```php
public function getDefaultDriver()
{
    return $this->app['config']['session.driver'];
}
```

這就是 Laravel [`config/session.php`](https://github.com/laravel/laravel/blob/v5.7.0/config/session.php#L19) 的 driver 設定。從這個設定檔的註解也可以知道，driver 有非常多種，如 `file`、`database`、`memcached` 等，這也剛好對應類別圖的 `SessionHandlerInterface` 實作。

如果設定是 file 的話，driver 又是怎麼被建構出來的呢，接著繼續看 [`createDriver()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Support/Manager.php#L85-L100)：

```php
protected function createDriver($driver)
{
    // 如果有設定自定義建構的話，就使用
    if (isset($this->customCreators[$driver])) {
        return $this->callCustomCreator($driver);
    } else {
        // 呼叫 createFileDriver 建構
        $method = 'create'.Str::studly($driver).'Driver';

        if (method_exists($this, $method)) {
            return $this->$method();
        }
    }
    
    // 都不是的話，只好丟例外
    throw new InvalidArgumentException("Driver [$driver] not supported.");
}
```

這裡的 `createFileDriver` 或是其他 driver 會是由子類別實作了，來繼續看 file driver 怎麼做的。

```php
protected function createFileDriver()
{
    return $this->createNativeDriver();
}

protected function createNativeDriver()
{
    // 取得設定的 session.lifetime
    $lifetime = $this->app['config']['session.lifetime'];

    // 建構實例
    return $this->buildSession(new FileSessionHandler(
        $this->app['files'], $this->app['config']['session.files'], $lifetime
    ));
}
```

這裡的 `$this->app['files']` 是 `Illuminate\Filesystem\Filesystem` 實例，而 `session.files` 與 `session.lifetime` 則是設定。

> 其他 handler 的分析方法也是依此類推，就先略過了。

`FileSessionHandler` 實作了 `SessionHandlerInterface`，這也是 PHP 提供的介面，搭配 [`session_set_save_handler()`](http://php.net/manual/en/function.session-set-save-handler.php) 可以用在自定義內建 session 的實作，也就是 `$_SESSION` 實際背後會處理細節，是可以自定義的。

換句話說，Laravel 所實作的五個 handler 不僅可以用在 SessionManager 上，也可以用在 PHP 內建的 `$_SESSION` 上，會這樣設計是有原因的，後面會再提到。

這五個實作都有一個共同特色，就是下面這兩個方法都是回傳 `true`：

```php
public function open($savePath, $sessionName)
{
    return true;
}

public function close()
{
    return true;
}
```

其他實作則依不同的 handler 有不同的存取方法，如 `CacheBasedSessionHandler` 就很好理解：

```php
public function read($sessionId)
{
    // 從 cache 實例拿資料，預設會是空字串
    return $this->cache->get($sessionId, '');
}

public function write($sessionId, $data)
{
    // 寫資料
    return $this->cache->put($sessionId, $data, $this->minutes);
}

public function destroy($sessionId)
{
    // 移除 session 資料
    return $this->cache->forget($sessionId);
}

public function gc($lifetime)
{
    // 不需做事，因為 Cache 實作如 Redis 都有 expire time 
    return true;
}
```

既然一開始有提到 SessionManager 不處理資料，實際處理資料的是 Store，或者說是 `Illuminate\Contracts\Session\Session`，Laravel 又是如何使用它的呢？從類別圖與上面的程式碼分析可以猜得出來，Laravel 自幹了 Session 處理機制，但它又是如何知道進來的 request 是來自同一個 client 呢？

這些秘密就在 [`StartSession`][] 這個 middleware 裡，明天再繼續分析。

[Session]: https://github.com/laravel/framework/tree/v5.7.6/src/Illuminate/Session
[`SessionManager`]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Session/SessionManager.php
[`StartSession`]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Session/Middleware/StartSession.php
