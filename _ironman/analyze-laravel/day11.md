---
title: 分析 Session（2）
---

先回顧一下類別圖，等等的說明搭著圖看會更好理解。

![](http://www.plantuml.com/plantuml/png/bP9FJm913CNlyocQU7Nu0CGG8chae0UvxgNi5fWuT3PjLqB4xwwoJ1337_Qqa-Rz-jg-7QgXMBEC3gTgWgL16L4LnZ4soy1eL4oQkavYnGiopadWqm7SG2NXWqIX3oY2wrkOM1A2m6h89Ralvm8RoGnBWWcfXiJFo5Ka6UVwNl7NRvHuEuaM8omNLBnHdJHOalKb_IENigxjnoa_IIunkz7orxapczzjVAIP-RpFhduEITwtbt7jVNeIvWlhRGRNJPFNg5hQRmQvsy44uFq0_cdxmBJAUHm5ZkhQOlB-P6XxdopjaCOsqdjKgWxRGw-fVwzoolGabtoLLkol_856ARq7wcRzW8PJr8xKKuWTYTScncx4aBXgbl4R)

昨天有提到：

> Laravel 所實作的五個 handler 不僅可以用在 SessionManager 上，也可以用在 PHP 內建的 `$_SESSION` 上

今天要來講原因了：因為沒有 `StartSession` 這個 middleware，的話，這個 SessionManager 是不會自動 work 的。但 SessionManager 又高度依賴 Laravel 內建的設定結構，（指 `config/session.php`），因此如果要讓這個元件可以一般化（generalization）的話，最好的方法就是實作 `SessionHandlerInterface`，這樣就能在所有 PHP 環境下使用了。

而這個設計也同時牽動了另一個設計：也就是讓 Store 聚合 SessionHandlerInterface 的設計，它們兩個的關係也是使用了 strategy pattern。

Strategy pattern 確實是一個符合[開關原則（Open-close principle）][Refactoring Day08]的最佳實踐，但它同時也有一個嚴重的缺陷：這麼多 strategy，開發者要怎麼知道要使用哪一個，因此有兩種做法：直接使用，比方說直接把 `FileSessionHandler` 拿來用，這樣就容易違反[最小知識原則（Least Knowledge Principle）][Refactoring Day12]，因為類別間的知識，知道對方的細節越少越好，最好是只要依賴抽象 `SessionHandlerInterface` 就好，而不要依賴細節 `FileSessionHandler`，因此有了第二種方法，就像 SessionManager 一樣，使用某個角色來管理這些 strategy，而這個方法則容易違反[單一職責原則（Single responsibility principle）][Refactoring Day07]，建構資訊容易集中在這個類別上，就會顯得很雜亂，因此或許大家也會覺得 SessionManager 的程式碼不一定好找，正是因為這個原因，而且是兩倍。因為 `SessionManager` 與 `Session` 的關係是 strategy pattern；`Store` 與 `SessionHandlerInterface` 的關係也是 strategy pattern。

原本或許只要 `SessionManager` 直接跟各種不同實作的 `Store` 做成 strategy pattern 就好，但因為 Laravel 對 Store 有自己一套處理介面，還有加密需求等，所以並不適合把 `SessionHandlerInterface` 直接實作在 `Store`，所以才會演變成現在這樣的設計。

## Laravel 如何知道來者何人？

Session 機制的原理是，使用一個隨機名稱，存放在 cookie 並設定過期時間，接著後端收到這個 cookie 的名稱後，以它為 key，在後端 Store 裡面取得對應儲存的資料。

PHP 內建的 `session_start()` 把這些實作都完成了，而 Laravel 則是自己刻了一套：也就是在 StartSession 這個 middleware 裡。Middleware 的原理在介紹 [Pipeline][Day07] 時，已經說明如何運行了，現在直接從 `handle()` 說明

```php
public function handle($request, Closure $next)
{
    // 標記 session 已被 middleware 處理過了，這會在 terminate() 用到
    $this->sessionHandled = true;

    // 如果有設定的話，才會啟用 session 功能
    if ($this->sessionConfigured()) {
        // 將 session 實例設定給 Request 實例
        $request->setLaravelSession(
            // 啟動並回傳 session 實例
            $session = $this->startSession($request)
        );

        // 將過期的 session 移除
        $this->collectGarbage($session);
    }

    // 交接給下一棒
    $response = $next($request);

    // 一樣，當 session 有設定的時候，才會處理該做的事 
    if ($this->sessionConfigured()) {
        // 有必要的話，它會儲存現在的 url
        $this->storeCurrentUrl($request, $session);

        // 最重要的，就是把剛剛說的 session key，設定到 cookie 裡
        $this->addCookieToResponse($response, $session);
    }

    return $response;
}
```

剛剛有提到 PHP 原生的 session 已經內建實作了寫 cookie 和儲存資料的行為，而這裡有趣的是，整個流程並沒有儲存 session 資料。那到底是什麼時候做呢？答案是 `terminate()`：

```php
public function terminate($request, $response)
{
    if ($this->sessionHandled && $this->sessionConfigured() && ! $this->usingCookieSessions()) {
        $this->manager->driver()->save();
    }
}
```

接著，另一個細節：cookie 的名稱是哪時決定的？這 `startSession()` 裡：

```php
protected function startSession(Request $request)
{
    return tap($this->getSession($request), function ($session) use ($request) {
        $session->setRequestOnHandler($request);

        $session->start();
    });
}
```

這個 tap() 的功能很特別，說明上有點困難，直接舉例它其實等價如下：

```php
protected function startSession(Request $request)
{
    $session = $this->getSession($request);
    
    $session->setRequestOnHandler($request);
    
    $session->start();
    
    return $session;
}
```

接著來看看 `getSession()` 是如何取得實例的：

```php
public function getSession(Request $request)
{
    // 使用預設 driver 取得實例
    return tap($this->manager->driver(), function ($session) use ($request) {
        // 設定 session id，這個 id 是從 cookie 取得的，key 是在 config 裡面設定的
        $session->setId($request->cookies->get($session->getName()));
    });
}
```

就是由 `setId()` 決定了 session key 的。裡面實作如下：

```php
public function setId($id)
{
    $this->id = $this->isValidId($id) ? $id : $this->generateSessionId();
}
```

所以在第一次進來的時候，就會產生新的 ID 了。

到目前為止，Session 的運作原理差不多就分析完畢了。

## CookieSessionHandler

這是一個特殊的 handler，某些實作正是針對它而 workaround 的。首先我們會發現 StartSession 有個特別的方法 `usingCookieSessions()` 在判斷是不是這個 handler：

```
protected function usingCookieSessions()
{
    if ($this->sessionConfigured()) {
        return $this->manager->driver()->getHandler() instanceof CookieSessionHandler;
    }

    return false;
}
```

使用到它的時機有兩個，一個是 `terminate()` 時，另一個是 `addCookieToResponse()`。在說明之前，先了解 CookieSessionHandler 實作：其實就是把 cookie 當作是存放 session 的空間。

還記得 [bootstrap 流程][Day02]，曾提過這段程式碼：

```php
$response->send();
```

這會把網頁內容全都輸出到 client 上，所以顯而易見，`terminate()` 不需要儲存，而是要移到 `addCookieToResponse()` 在準備 [cookie][Day09] 的時候儲存。

因 CookieSessionHandler 會需要從 request 取得 cookie 資料，才有辦法解析出存放的 session 內容。因此會有一個方法 `setRequestOnHandler()` 是把 request 存放到 handler 裡，這也是特別為了它而寫的：

```php
public function setRequestOnHandler($request)
{
    if ($this->handlerNeedsRequest()) {
        $this->handler->setRequest($request);
    }
}
```

而其他的 handler 性質都差不多，所以會走一樣的流程。

## 今日總結

Session 雖然類別多，但結構算簡單，並且也有些設計理念存在，是個練習分析原始碼的好目標。

[Refactoring Day07]: /src/ironman-refactoring-30-days/day07.md
[Refactoring Day08]: /src/ironman-refactoring-30-days/day08.md
[Refactoring Day12]: /src/ironman-refactoring-30-days/day12.md

[Day02]: day02.md
[Day07]: day07.md
[Day09]: day09.md
