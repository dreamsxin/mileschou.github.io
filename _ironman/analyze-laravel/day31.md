---
title: 分析自定義錯誤頁
---

[官方](https://laravel.com/docs/5.7/errors#http-exceptions)有提到自定義錯誤頁可以如何簡單達成。筆者遇到的問題是，想自定義錯誤頁，並在 debug 模式下，當隨意丟例外的時候，要在頁面某個地方列出 call stack trace。

> 從今天開始，會開始換來分享筆者實作功能中遇到問題，而去追原始碼的過程。不知道能持續多久，就繼續寫吧！

結論先講：這無法單純使用自定義錯誤頁實作出來的，需要客製化某些程式才有辦法做。因為只是 debug 要用，所以筆者就立馬放棄了。

文件有提到自定義錯誤頁會接到 `abort()` 函式產生的 HttpException 並注入頁面的 $exception 變數。

```php
function abort($code, $message = '', array $headers = [])
{
    if ($code instanceof Response) {
        throw new HttpResponseException($code);
    } elseif ($code instanceof Responsable) {
        throw new HttpResponseException($code->toResponse(request()));
    }

    app()->abort($code, $message, $headers);
}

// Illuminate\Foundation\Application::abort()

public function abort($code, $message = '', array $headers = [])
{
    if ($code == 404) {
        throw new NotFoundHttpException($message);
    }

    throw new HttpException($code, $message, null, $headers);
}
```

從上面可以了解 `abort()` 的任務都是丟例外，因此我們首先要關注的應該是錯誤處理。

## Error Handler

在 [Pipeline][Day08] 曾提到，[Routing\Pipeline][] 繼承 [Pipeline][] 後有覆寫一段程式，正是在做錯誤處理：

```php
try {
    return $destination($passable);
} catch (Exception $e) {
    return $this->handleException($passable, $e);
} catch (Throwable $e) {
    return $this->handleException($passable, new FatalThrowableError($e));
}
```

而在[分析 bootstrap 流程][Day02]也提過，從 request 產出 response 的 `sendRequestThroughRouter()` 方法裡面，是最一開始呼叫 Pipeline 的地方：

```php
return (new Pipeline($this->app))
            ->send($request)
            ->through($this->app->shouldSkipMiddleware() ? [] : $this->middleware)
            ->then($this->dispatchToRouter());
```

從以上兩點可以得知，Routing\Pipeline 所做的錯誤處理的有效範圍，從進全域的 middleware 開始，到全域的 middleware 回傳最後的 response 之後結束。

`handleException()` 回顧如下：

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

這段程式碼會看到，它使用了 `ExceptionHandler::render()` 方法，產生錯誤的 response，接著才回傳出去給 Http Kernel 處理。Laravel 預設會另外建一個 `Handler.php` 檔繼承 ExceptionHandler，然後覆寫 `render()`：

```php
public function render($request, Exception $exception)
{
    return parent::render($request, $exception);
}
```

如果有要自定義處理 Exception，可以在這裡做。預設的 `render()` 實作如下：

```php
public function render($request, Exception $e)
{
    if (method_exists($e, 'render') && $response = $e->render($request)) {
        // 如果 Exception 有實作 render() 方法，就呼叫它並回傳
        return Router::toResponse($request, $response);
    } elseif ($e instanceof Responsable) {
        // 如果 Exception 可以轉換成 response 就直接轉
        return $e->toResponse($request);
    }

    // 這裡 Laravel 會把某幾個特定的 Exception 換成合適的 HttpException
    $e = $this->prepareException($e);

    if ($e instanceof HttpResponseException) {
        // 有另外包一個 Response 的 Exception
        return $e->getResponse();
    } elseif ($e instanceof AuthenticationException) {
        // 未認證 Exception
        return $this->unauthenticated($request, $e);
    } elseif ($e instanceof ValidationException) {
        // 未驗證 Exception
        return $this->convertValidationExceptionToResponse($e, $request);
    }

    // 如果 request 預期要 JSON 則準備 JSON response，反正準備一般的 response
    return $request->expectsJson()
                    ? $this->prepareJsonResponse($request, $e)
                    : $this->prepareResponse($request, $e);
}
```

普通的 Exception 與 HttpException 都不符合上面判斷的條件，因此會到最下面。因為是錯誤頁，所以 `expectsJson()` 將會回傳 false，而回傳 `prepareResponse()` 的結果

```php
protected function prepareResponse($request, Exception $e)
{
    // 如果不是 HttpException，且 debug 模式開啟的時候
    if (! $this->isHttpException($e) && config('app.debug')) {
        // 使用 convertExceptionToResponse() 方法，產生 exception 專用的 response 
        return $this->toIlluminateResponse($this->convertExceptionToResponse($e), $e);
    }

    // 如果不是 isHttpException，且 debug 模式「關閉」的時候，把 exception 轉成 HttpException
    if (! $this->isHttpException($e)) {
        $e = new HttpException(500, $e->getMessage());
    }

    // 將 HttpException 轉換成 response
    return $this->toIlluminateResponse(
        $this->renderHttpException($e), $e
    );
}
```

第一個判斷裡面輸出的結果，事實上就是平常看到的 call stack trace 頁，主要在裡面找到的 `renderExceptionContent()` 方法

```php
protected function convertExceptionToResponse(Exception $e)
{
    return SymfonyResponse::create(
        $this->renderExceptionContent($e),
        $this->isHttpException($e) ? $e->getStatusCode() : 500,
        $this->isHttpException($e) ? $e->getHeaders() : []
    );
}

protected function renderExceptionContent(Exception $e)
{
    try {
        return config('app.debug') && class_exists(Whoops::class)
                    ? $this->renderExceptionWithWhoops($e)
                    : $this->renderExceptionWithSymfony($e, config('app.debug'));
    } catch (Exception $e) {
        return $this->renderExceptionWithSymfony($e, config('app.debug'));
    }
}
```

`renderExceptionWithSymfony()` 將會依照 debug 參數的開或關，而定輸出的內容有沒有 call stack trace。

而自定義錯誤頁的實作在 `renderHttpException()` 裡：

```php
protected function renderHttpException(HttpException $e)
{
    // 註冊 errors namespace，也就是文件裡提到的 resources/views/errors/*
    $this->registerErrorViewPaths();

    // 如果 errors 裡面有找到對應 status code 的樣版，就輸出它。
    if (view()->exists($view = "errors::{$e->getStatusCode()}")) {
        return response()->view($view, [
            'errors' => new ViewErrorBag,
            'exception' => $e,
        ], $e->getStatusCode(), $e->getHeaders());
    }

    // 沒找到就用預設錯誤頁輸出
    return $this->convertExceptionToResponse($e);
}
```

從上面的分析可以知道，當 debug 模式開啟的時候，隨意丟例外是會符合 `prepareResponse()` 第一個判斷，並輸出預設的 call stack trace 頁面；丟 HttpException 才有辦法進到自定義錯誤頁。

了解了 Laravel 錯誤處理機制之後可以發現，大部分可預期的狀況丟 HttpException 或使用 `abort()` 處理錯誤比較適合，這也是 Laravel 預期的。自定義例外可以實作 `render()` 讓 Handler 自動處理。筆者遇到的狀況則是第三方 library 使用過程中丟例外，使用 try catch 配合 `abort()` 來處理錯誤即可。

[Routing\Pipeline]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Routing/Pipeline.php
[Pipeline]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Pipeline/Pipeline.php

[Day02]: day02.md
[Day08]: day08.md
