---
title: 分析 Pipeline（1）
---

在[分析 bootstrap 流程][Day02]的最後面的 `handle()` 時，有提到[一段程式碼](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Http/Kernel.php#L148-L151)。

```php
// 解析 request 並執行 Controller
return (new Pipeline($this->app))
            ->send($request)
            ->through($this->app->shouldSkipMiddleware() ? [] : $this->middleware)
            ->then($this->dispatchToRouter());
```

是的，今天要來分析上面看到的 `Pipeline`。

## 類別圖

Laravel 5.7 裡，跟 Pipeline 相關的主要角色有三個：

> 雖然還有 Hub，不過它很簡單，所以先不提。

* [Illuminate\Contracts\Pipeline\Pipeline](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Contracts/Pipeline/Pipeline.php)
* [Illuminate\Pipeline\Pipeline](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Pipeline/Pipeline.php)
* [Illuminate\Routing\Pipeline](https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Routing/Pipeline.php)

類別圖如下：

![](http://www.plantuml.com/plantuml/png/VS-nweCm4CVnFK-H8KEaw1Dq49owbSukgRc_1fABv2ukrdUl_r9GskAMyE4Blwk9JU8Sl738aFvC1_BYVGuE3KFRHEHaEgRswaRm3a7EGigJdCsTNh980hHQhPy9FAJYatb8CVU3LiHnf2-UdD4g00_H_aW1TUCZvGHIMI3-N-KY5c8HudZc-L5L-qlUi3t44QvvMUxpMypiiD_g6j3cu9y0)

PlantUML 原始碼：

```
@startuml
interface Illuminate\Contracts\Pipeline {
  + {abstract} send($traveler)
  + {abstract} through($stops)
  + {abstract} via($method)
  + {abstract} then(Closure $destination)
}

Illuminate\Contracts\Pipeline <|.. Illuminate\Pipeline\Pipeline
Illuminate\Pipeline\Pipeline <|-- Illuminate\Routing\Pipeline
@enduml
```

繼承與實作關係很單純，跟 [Application][Day05] 一樣，可以了解一下繼承有沒有符合[里氏替換原則][Refactoring Day09]。

參考註解，`Routing\Pipeline` 繼承並沒有修改原有行為，而是為了加上 try/catch，等後面一點再來分析這個類別。

## Pipeline

再來就來看 Pipeline 在做什麼了。它與 DevOps 提到的 [Pipeline][CI Day21] 類似，是一個關卡接著一個關卡的流程。

從如何使用，來了解 Pipeline，或許是一個比較好的方法：

```php
// 解析 request 並執行 Controller
return (new Pipeline($this->app))
            ->send($request)
            ->through($this->app->shouldSkipMiddleware() ? [] : $this->middleware)
            ->then($this->dispatchToRouter());
```

首先是 `send()`，它非常簡單，只是先保存好一個原物料來當輸入。HTTP Kernel 使用 request 作為輸入。

```php
public function send($passable)
{
    $this->passable = $passable;

    return $this;
}
```

再來 `through()`，則是定義有什麼樣的「水管」，HTTP Kernel 使用 middleware 作為水管。

```php
public function through($pipes)
{
    $this->pipes = is_array($pipes) ? $pipes : func_get_args();

    return $this;
}
```

最後 `then()`，會傳入一個作為水管最後「目標」的 Closure。HTTP Kernel 使用 `$this->dispatchToRouter()` 的結果作為目標。

```php
public function then(Closure $destination)
{
    $pipeline = array_reduce(
        array_reverse($this->pipes), $this->carry(), $this->prepareDestination($destination)
    );

    return $pipeline($this->passable);
}
```

而這裡的實作正是最近幾天最難理解的。[`array_reduce()`](http://php.net/manual/en/function.array-reduce.php) 的功能是把一個 array 拆分成個別元素，然後依序傳入某個 callable，每個元素的輸出，都會成為下個元素的輸入，最終轉化成另一種結果。而第一個元素的輸入是可以自己指定的。而 callback 的格式如下：

```php
function($carry, $value) {
    // Do something
    return $newCarry;
} 
```

可以開始看程式了，首先看比較好懂的 `prepareDestination()`。

```php
protected function prepareDestination(Closure $destination)
{
    return function ($passable) use ($destination) {
        return $destination($passable);
    };
}
```

它其實就只是再包裝過一次，會這麼做的理由是為了讓 `Routing\Pipeline` 包一層 try/catch。

再來就是最困難的 `carry()`。

```php
protected function carry()
{
    return function ($stack, $pipe) {
        return function ($passable) use ($stack, $pipe) {
            if (is_callable($pipe)) {
                // 如果是 callable 就呼叫吧
                return $pipe($passable, $stack);
            } elseif (! is_object($pipe)) {
                // 如果不是物件的話，就是字串。字串裡會有建置的資訊，解析後再建置即可
                list($name, $parameters) = $this->parsePipeString($pipe);
                
                $pipe = $this->getContainer()->make($name);

                // 組合傳入值
                $parameters = array_merge([$passable, $stack], $parameters);
            } else {
                // 都不是的話，會期望 $pipe 是物件
                $parameters = [$passable, $stack];
            }

            // 預設的 `method` 是 handle，如果有使用 via() 的話可以調整。如果物件沒實作這個方法的話，就會假設它有實作 __invoke。
            $response = method_exists($pipe, $this->method)
                            ? $pipe->{$this->method}(...$parameters)
                            : $pipe(...$parameters);

            // 如果 response 是 Responsable 的話，就傳入 request 轉 response；不然就直接回傳了 
            return $response instanceof Responsable
                        ? $response->toResponse($this->container->make(Request::class))
                        : $response;
        };
    };
}
```

裡面的流程都很單純，難的地方在最外層是 Closure 包 Closure。先假設 array，並用比較簡單的寫法把它改成 inline 試試：

```php
// 從上面的原始碼得知，這個其實是 middleware 的 handle 實作
$pipe = [
    function($request, $next) {
        return $next($request) . '1';
    },
    function($request, $next) {
        return $next($request) . '2';
    },
    function($request, $next) {
        return $next($request) . '3';
    },
];

$pipeline = array_reduce(
    array_reverse($pipe),
    function ($stack, $pipe) {
        return function ($passable) use ($stack, $pipe) {
            return $pipe($passable, $stack);
        };
    },
    function ($passable) {
        return 'response';
    }
);

$pipeline('request'); // return 'response321'
```

由我們對 `array_reduce` 與 `array_reverse` 的理解，可以知道第二個 callback 被執行了三次，我們試著把執行過程展開來看看。

第一次執行的情況是這樣的：

```php
$stack0 = function ($passable) {
    return 'response';
};

$pipe3 = function($request, $next) {
    return $next($request) . '3';
}

return function ($passable) use ($stack0, $pipe3) {
    return $pipe3($passable, $stack0);
};
```

單看這段程式碼，可以知道 $pipe3 的 $next，實際上就是 $stack0。所以回傳的 Closure 執行結果會是 `response3`。

根據 [Closure 的特性][Golang Day12]，我們可以知道回傳的 Closure 的變數會被包起來，接著再傳給下一個：

```php
// 這次的 stack 就是上面的 return
$stack3 = function ($passable) {
    return $pipe3($passable, $stack0);
};

$pipe2 = function($request, $next) {
    return $next($request) . '2';
}

return function ($passable) use ($stack3, $pipe2) {
    return $pipe2($passable, $stack3);
};
```

跟上面類似，$pipe2 的 $next 其實就是 $stack3，執行結果會是 `response32`。依此類推最後一次：

```php
$stack2 = function ($passable) {
    return $pipe($passable, $stack);
};

$pipe1 = function($request, $next) {
    return $next($request) . '1';
}

return function ($passable) use ($stack2, $pipe1) {
    return $pipe1($passable, $stack2);
};
```

$pipe1 的 $next 其實就是 $stack2，執行結果就是 `response321`。

> 這個過程就很像是在遞迴（recursion），但又比遞迴更為神奇的寫法。筆者目前無法確定為何要使用這麼難理解的寫法，也許目的是為了效能。

其他套件也有類似的做法，如 [`GuzzleHttp\Middleware`](https://github.com/guzzle/guzzle/blob/6.3.3/src/Middleware.php) 也是用類似的寫法。而 Slim Framework 也有實作 [Middleware](https://github.com/slimphp/Slim/blob/3.11.0/Slim/MiddlewareAwareTrait.php#L53-L81)，但它在 [3.8.x](https://github.com/slimphp/Slim/blob/3.8.1/Slim/MiddlewareAwareTrait.php#L66) 之前是使用 [SplStack](http://php.net/manual/class.splstack.php) 存放 Closure，後來 [3.9](https://github.com/slimphp/Slim/blob/3.9.0/Slim/MiddlewareAwareTrait.php#L63-L69) 開始才改用類似的寫法。

今天先看到這裡，明天繼續看 `Routing\Pipeline`。

[CI Day21]: /_ironman-intro-of-ci/day21.md
[Refactoring Day09]: /src/ironman-refactoring-30-days/day09.md
[Golang Day12]: /src/ironman-start-golang-30-days/day12.md#closure

[Day02]: day02.md
[Day05]: day05.md
