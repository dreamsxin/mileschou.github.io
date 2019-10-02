---
title: 分析 Pipeline（2）
---

昨天使用範例說明 Pipeline 的包裝方法，相信至少可以略懂個一二。接下來先補充一下 [`parsePipeString()`](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Pipeline/Pipeline.php#L167-L176) 在做什麼。

```php
protected function parsePipeString($pipe)
{
    // 使用冒號 `:` 把 $pipe 拆成兩個元素塞到 $name 與 $parameters，沒得拆的話會使用 [] 補到 $parameters 裡
    list($name, $parameters) = array_pad(explode(':', $pipe, 2), 2, []);

    // 如果有拆成的話，這會是字串，再把它用逗號拆成 array
    if (is_string($parameters)) {
        $parameters = explode(',', $parameters);
    }

    return [$name, $parameters];
}
```

昨天有提到，Pipeline 其實正是 middleware 的實作，而在 Laravel 樣版裡，Http Kernel 其實有定義一個 [middleware](https://github.com/laravel/laravel/blob/v5.7.0/app/Http/Kernel.php#L41) 是這個：

```
throttle:60,1
```

是的，就是它！於是 `throttle` 會被轉成 $name 傳入 `$app->make()`，$parameters 則會補到 `[$passable, $stack]` 後面，成為參數的一部分。同時這也是有的 middleware 如 [ThrottleRequests](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Routing/Middleware/ThrottleRequests.php#L46) 為什麼 `handle()` 可以接這麼多參數的原因。

---

接著我們來看 [Hub](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Pipeline/Hub.php)。

它與 Pipeline 的關係圖如下：

![](http://www.plantuml.com/plantuml/png/ZP31JiCm38RlUGeVSiW4tHE0D6aNk27EkwIjMODSfuhjNhQzEp09L94YTelq-_F_nJlHMDH6SeaLorli49w9R4mS5G_xp5fYft9uIHDIOlnvmCa1tC4fjd8TkO0Wzy5hYJCIbitlM8UIxJW4BvedgU8vnU17r27tAoXos5CMAmY-Hz4llPHvuoxkPlCdQslfwJCDFhVlsEaz-EdxTu_0HdJTV-Cz7ixRxSAWdd3_wbKxbk42NsrlcYNvcaqJ7-loTRhvitM7tDj87m00)

```
@startuml
interface Illuminate\Contracts\Pipeline\Pipeline {
  + {abstract} send($traveler)
  + {abstract} through($stops)
  + {abstract} via($method)
  + {abstract} then(Closure $destination)
}

interface Illuminate\Contracts\Pipeline\Hub {
  + {abstract} pipe($object, $pipeline = null)
}

Illuminate\Contracts\Pipeline\Pipeline <|.. Illuminate\Pipeline\Pipeline
Illuminate\Contracts\Pipeline\Hub <|.. Illuminate\Pipeline\Hub
Illuminate\Pipeline\Pipeline <|-- Illuminate\Routing\Pipeline
Illuminate\Pipeline\Pipeline <- Illuminate\Pipeline\Hub
@enduml
```

先看一下 `pipe()` 的實作：

```php
public function pipe($object, $pipeline = null)
{
    $pipeline = $pipeline ?: 'default';

    return call_user_func(
        $this->pipelines[$pipeline], new Pipeline($this->container), $object
    );
}
```

從這裡可以了解，`$this->pipelines[$pipeline]` 實際要放的 Closure 應該要長的像這樣：

```php
function(Pipeline $pipeline, $object) {

}
```

它的用途大概是，我們可以定義很多種流程，然後依不同的情境執行不同的流程。

```php
$hub = $app->make(Hub::class);

if ($request->isAjax()) {
    return $hub->pipe($request, 'ajax');
}

return $hub->pipe($request);
```

而事實上，Laravel 預設樣版並沒有使用 Hub 的功能。

---

最後來看一下 Routing 的繼承實作，來看其中[一段](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Routing/Pipeline.php#L26-L37)加上例外處理的程式碼：

```php
try {
    return $destination($passable);
} catch (Exception $e) {
    return $this->handleException($passable, $e);
} catch (Throwable $e) {
    return $this->handleException($passable, new FatalThrowableError($e));
}
```

這裡可以看到會由 `handleException()` 來處理例外，來看一下這段程式碼，會有意外的發現：

```php
protected function handleException($passable, Exception $e)
{
    if (! $this->container->bound(ExceptionHandler::class) ||
        ! $passable instanceof Request) {
        throw $e;
    }

    $handler = $this->container->make(ExceptionHandler::class);

    $handler->report($e);

    $response = $handler->render($passable, $e);

    if (method_exists($response, 'withException')) {
        $response->withException($e);
    }

    return $response;
}
```

如果還有印象的話，`ExceptionHandler` 正是[分析 bootstrap 流程][Day02]一開始的「綁定實作」之一，也就是 `$app->singleton()` 所綁定的其中一個類別名。這裡可以發現，它會呼叫 `report()` 以及 `render()`，剛好就是 Laravel 樣版的 [`Handler` 實作](https://github.com/laravel/laravel/blob/v5.7.0/app/Exceptions/Handler.php)的一部分。

```php
namespace App\Exceptions;

use Exception;
use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;

class Handler extends ExceptionHandler
{
    public function report(Exception $exception)
    {
        parent::report($exception);
    }

    public function render($request, Exception $exception)
    {
        return parent::render($request, $exception);
    }
}
```

我們知道文件裡有寫如何使用 [Exception Handler](https://laravel.com/docs/5.7/errors#the-exception-handler)，而實際上抓 Exception 並轉交給 Handler 處理的實作就是在這裡。

## 今日總結

這兩天 Pipeline 的 Closure 實作，並不是那麼好懂，不過當理解之後，[Golang](https://github.com/MilesChou/book-start-golang-30-days) 或 Javascript 之類的語言，也都能使用類似的方法實作 middleware 哦。

[Day02]: day02.md
