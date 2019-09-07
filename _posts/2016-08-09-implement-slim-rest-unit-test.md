---
layout: post
title: 實作 Slim 的 REST 層單元測試
---

[Slim][] 本身框架很簡單，也很彈性。一開始還搞不懂，後來才知道原來它也可以這樣用來做測試

## Start With TDD

即然要用單元測試，不如就來 run TDD 吧

### Initial Testing Code

先來用 [Codeception][] 建測試檔案：

    $ php vendor/bin/codecept generate:test unit HelloWorld
    Test was created in /path/to/project/tests/unit/HelloWorldTest.php

第一個測試先簡單寫

```php
<?php
// File: tests/unit/HelloWorldTest.php

public function testHelloWorld()
{
    // Arrange
    $url = '/';
    
    // Act
    $response = '';
    $code = 0;
    
    // Assert
    $this->assertRegExp("/Hello/", (string) $response);
    $this->assertRegExp("/World/", (string) $response);
    $this->assertEquals(200, $code);
}
```

這裡可以很清楚知道測試意圖，也能知道後面該怎麼實作。

上面的 `$response` 和 `$code` 目前都是假值，接著我們要做的就是要從 Slim 的程式取得。 Slim 即然能輸出到 Browser ，那輸出字串絕對可以。

### Get Slim App

首先我們要取得 Slim App

把官網的範例稍微修改一下如下： 

```php
<?php
// File: public/index.php

use \Psr\Http\Message\ServerRequestInterface as Request;
use \Psr\Http\Message\ResponseInterface as Response;

require __DIR__ '/../vendor/autoload.php';

$app = new \Slim\App();
$app->get('/', function (Request $request, Response $response) {
    $response->getBody()->write("Hello World");
    return $response;
});
$app->run();
```

可以啟動 web server ，執行結果跟上面的測試意圖是吻合的。

接著可以觀察到，它在 run 之前，都只是 route 定義，以測試和上線的角度來看，他們 route 應該會是一樣的，只是執行的方法不同。因此我們可以把 run 和 route 拆開：

```php
<?php
// File: public/index.php

require __DIR__ . '/../bootstrap.php';
$app->run();
```

```php
<?php
// File: bootstrap.php

use \Psr\Http\Message\ServerRequestInterface as Request;
use \Psr\Http\Message\ResponseInterface as Response;

require __DIR__ '/vendor/autoload.php';

$app = new \Slim\App();
$app->get('/', function (Request $request, Response $response) {
    $response->getBody()->write("Hello World");
    return $response;
});
```

---

當然個人覺得改的 functional 一點比較有感

```php
<?php
// File: public/index.php

$app = require __DIR__ . '/../bootstrap.php';
$app->run();
```

```php
<?php
// File: bootstrap.php

use \Psr\Http\Message\ServerRequestInterface as Request;
use \Psr\Http\Message\ResponseInterface as Response;

require __DIR__ '/vendor/autoload.php';

$app = new \Slim\App();
$app->get('/', function (Request $request, Response $response) {
    $response->getBody()->write("Hello World");
    return $response;
});

return $app;
```

---

回到測試，所以我現在能取得未執行的 app 元件，也能正常取得 response 和 code 了

```php
<?php
// File: tests/unit/HelloWorldTest.php

public function testHelloWorld()
{
    // Arrange
    $app = require __DIR__ . '/../../bootstrap.php';
    $url = '/';
    
    // Act
    $app->run(true);
    $response = $app->getContainer()['response'];
    
    // Assert
    $this->assertRegExp("/Hello/", (string) $response->getBody());
    $this->assertRegExp("/World/", (string) $response->getBody());
    $this->assertEquals(200, $response->getStatusCode());
}
```

### Environment Mock

欸等等， `$url` 還沒被用到耶！ `$url` 要配合 Environment Mock 和 [Dependency Container](http://www.slimframework.com/docs/concepts/di.html) 才能正常地傳到 App 裡

直接看結果

```php
<?php
// File: tests/unit/HelloWorldTest.php

public function testHelloWorld()
{
    // Arrange
    $app = require __DIR__ . '/../../bootstrap.php';
    $url = '/';
    
    $environmentMock = \Slim\Http\Environment::mock([
    	'REQUEST_METHOD' => 'GET',
    	'REQUEST_URI' => $url,
    ]);
    
    $container = $app->getContainer();
    $container['environment'] = $environmentMock;
    
    // Act
    $app->run(true);
    $response = $container['response'];
    
    // Assert
    $this->assertRegExp("/Hello/", (string) $response->getBody());
    $this->assertRegExp("/World/", (string) $response->getBody());
    $this->assertEquals(200, $response->getStatusCode());
}
```

除了可以用在 URL 外，只要是 Container 能控制的 Dependency 都能用 mock 替換掉。

## Conclusion

Slim 目前用起來還蠻有趣的，簡單好用也方便調校。只是測試相關文件(e.g. Environment Mock 就沒有文件說明，只能去程式找)不是很完整，只能靠經驗去實作。

其他 [Micro Phalcon][] 和 [Lumen][] 應該也都可以試玩看看

[Slim]: http://www.slimframework.com/
[Codeception]: http://codeception.com/
[Lumen]: https://lumen.laravel.com/
[Micro Phalcon]: https://docs.phalconphp.com/en/latest/reference/micro.html
