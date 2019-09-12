---
title: 分析 Cookie
---

從 [Pipeline][Day07] 的分析，我們了解了 middleware 的執行流程，接下來我們來看與預設 middleware 相關的其中一個元件－－[Cookie][]。

## 類別圖

![](http://www.plantuml.com/plantuml/png/dO_1IiD0443l-nLpwA55cWyGaOfGh3Ufu2MNSJEjWxkpSNSM2Mt_tMsMGb5Kz9Gmy_BcPP4KesRl38jItA0bM3cNFGigjRT1DABLLDx2ArFxa2aJotPPXY4Ei3C05x33vpHo1tWx0jEcQIOzHlHKf6ds6SfIiOaKuijsIpgUwUhDD9sPWp7MOKhdRUlSzo5gUnFZAICfAjlHK3_wowzSxPlcp5-nq-CUe_bX1_FvzNTjbr2pmA9p_v6iH6aiVs9zUMHFHPaJWKPa_LMu7lmco52clWz2eksTQhyCMJfK3bBnerFe7LXAh5Wo2v8kU_S1)

```
@startuml
interface Illuminate\Contracts\Cookie\QueueingFactory {
  + {abstract} queue(...$parameters)
  + {abstract} unqueue($name)
  + {abstract} getQueuedCookies()
}

class Illuminate\Support\Arr {
  + {static} get()
}

Illuminate\Contracts\Cookie\QueueingFactory <|.. Illuminate\Cookie\CookieJar
Illuminate\Cookie\CookieJar --> Illuminate\Support\Arr : static call
Illuminate\Cookie\CookieJar --> Illuminate\Support\InteractsWithTime : use trait
Illuminate\Cookie\CookieJar --> Symfony\Component\HttpFoundation\Cookie : new instance
@enduml
```

這次也跟 Config 一樣，是個單純的元件。比較特別的是，它跟 `Symfony\Component\HttpFoundation\Cookie` 的關係是建立 instance 的角色。

從 Contract 的名稱與定義的行為看起來，它是一個 queue。而行為提供了加元素、移除元素、以及取得所有元素的方法。

接下來分別看這三個方法做了哪些事：

## queue()

[`queue()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Cookie/CookieJar.php#L132-L141) 的任務是加元素進這個 queue 物件。

```php
public function queue(...$parameters)
{
    // 如果傳入的第一個元素 Cookie 實例，就取得第一個元素；不是的話，預期會是傳入 make() 所需要的參數，再使用 make() 產生 Cookie 實例。
    if (head($parameters) instanceof Cookie) {
        $cookie = head($parameters);
    } else {
        $cookie = call_user_func_array([$this, 'make'], $parameters);
    }

    // 將實例存放在 queue 裡，使用 Cookie 的名稱當作 key
    $this->queued[$cookie->getName()] = $cookie;
}
```

從程式碼裡可以知道，這個元件使用 array 實作 queue，因此取得元素與移除元素的時間複雜度將會是 O(1)。

[`make()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Cookie/CookieJar.php#L63-L70) 的任務是產生 Cookie 實例，所以可以確定 queue 裡面所有的元素將會都是 `Cookie`

```php
public function make($name, $value, $minutes = 0, $path = null, $domain = null, $secure = null, $httpOnly = true, $raw = false, $sameSite = null)
{
    // 取得 Path / Domain 等設定
    list($path, $domain, $secure, $sameSite) = $this->getPathAndDomain($path, $domain, $secure, $sameSite);

    // 把 $minutes 轉換成到期日
    $time = ($minutes == 0) ? 0 : $this->availableAt($minutes * 60);

    // 產生實例
    return new Cookie($name, $value, $time, $path, $domain, $secure, $httpOnly, $raw, $sameSite);
}
```

產生到期日使用 [Carbon][Decompose Day02] 實作，應該是好理解的，產生實例也沒有什麼大問題，[`getPathAndDomain()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Cookie/CookieJar.php#L163-L166) 的實作如下：

```php
protected function getPathAndDomain($path, $domain, $secure = null, $sameSite = null)
{
    return [$path ?: $this->path, $domain ?: $this->domain, is_bool($secure) ? $secure : $this->secure, $sameSite ?: $this->sameSite];
}
```

`?:` 這個寫法的意思是：`$path` 是 `null` 的話，就使用 `$this->path`，其他依此類推。而 `$this` 相關的屬性並沒有初始化，但有一個公開方法 [`setDefaultPathAndDomain()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Cookie/CookieJar.php#L177-L182) 可以設定：

```php
public function setDefaultPathAndDomain($path, $domain, $secure = false, $sameSite = null)
{
    list($this->path, $this->domain, $this->secure, $this->sameSite) = [$path, $domain, $secure, $sameSite];

    return $this;
}
```

因為 queue 使用 array 實作，所以 [unqueue()](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Cookie/CookieJar.php#L149-L152) 和 [getQueuedCookies()](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Cookie/CookieJar.php#L189-L192) 的實作自然就會非常簡單：

```php
public function unqueue($name)
{
    unset($this->queued[$name]);
}

public function getQueuedCookies()
{
    return $this->queued;
}
```

> 雖然稱之為 queue，實作上比較像 hash table。

但到目前為止，並沒有任何 Cookie 的寫入與讀取，到底是哪裡實作的呢？答案就在 middleware [AddQueuedCookiesToResponse](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Cookie/Middleware/AddQueuedCookiesToResponse.php) 裡：

```php
public function handle($request, Closure $next)
{
    $response = $next($request);

    // 在取得 $response 後，在 $response 上追加 queue 裡面的所有 $cookie
    foreach ($this->cookies->getQueuedCookies() as $cookie) {
        $response->headers->setCookie($cookie);
    }

    return $response;
}
```

就這樣，非常的簡單，這也是 [Laravel 預設樣版](https://github.com/laravel/laravel/blob/v5.7.0/app/Http/Kernel.php#L32)會設定的 middleware。而平常使用，只要取得 CookieJar，然後把需要的 Cookie 加入 queue 即可。參考 [CookieServiceProvider](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Cookie/CookieServiceProvider.php)

> 要注意這裡的 domain 等設定是吃 [config/session.php](https://github.com/laravel/laravel/blob/v5.7.0/config/session.php) 裡面的設定。
```php
public function register()
{
    $this->app->singleton('cookie', function ($app) {
        $config = $app->make('config')->get('session');

        return (new CookieJar)->setDefaultPathAndDomain(
            $config['path'], $config['domain'], $config['secure'], $config['same_site'] ?? null
        );
    });
}
```

可以得知，Container 的 key 是叫 `cookie`，所以只要這樣寫就能取到單例的 CookieJar：

```php
app('cookie')->queue('new_cookie', 'some-value', 10);
```

Laravel 的程式碼可以這麼簡潔，有很大一部分也是歸工於 Symfony。

## 今日總結

以筆者的經驗來說，Cookie 的處理是麻煩的，但 Laravel 與 Symfony 讓這一切處理都變得非常簡單。偶爾翻翻原始碼，才有辦法思考什麼樣的設計才能讓其他開發者覺得好用，

[Cookie]: https://github.com/laravel/framework/tree/v5.7.6/src/Illuminate/Cookie

[Decompose Day02]: https://github.com/MilesChou/book-decompose-wheels/blob/master/docs/day02.md

[Day07]: day07.md
