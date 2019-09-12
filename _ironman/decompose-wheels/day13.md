---
title: Monolog（2）－－從使用它到了解它 
---

在開始拆解前，首先我們先了解該如何使用它，官方提供的 Basic Usage 如下：

```php
use Monolog\Logger;
use Monolog\Handler\StreamHandler;

// create a log channel
$log = new Logger('name');
$log->pushHandler(new StreamHandler('path/to/your.log', Logger::WARNING));

// add records to the log
$log->addWarning('Foo');
$log->addError('Bar');
```

> 以下為方便說明，皆把 Monolog namespace 省略

通常好的函式庫，從範例就能快速了解函式庫的基本架構。這段程式碼可以發現主要的核心物件是 `Logger`，而另外一個依附在 Logger 上的物件 `Handler\StreamHandler`。`Handler\StreamHandler` 實作了 `Handler\HandlerInterface`，這也是 `pushHandler` 方法所限制的物件型別。

而後面兩行新增 log 的方法，翻一下原始碼，會發現是由 `Logger` 轉接到 `Handler\StreamHandler` 和其他被加入的 Handler 上。

通常兩個物件如果是抽象層依賴的話，有可能會是 *Bridge Pattern* 或是 *Observer Pattern*；而 Bridge Pattern 又通常會是建構時期決定依賴的物件為何，因此 `Logger` 與 `Handler\HandlerInterface` 的關係基本上比較像是 *Observer Pattern*。關係圖如下：

![](http://www.plantuml.com/plantuml/png/SoWkIImgAStDuNBEIImkLl39JqzFBLAevb9Gq5OeA2tEy4ZCIyb9BTB8i5A0CcEWj6TUIMfHMc9ogYP4SNu1JAqcRhLSjL2BO0g2IufI4tEXF3Gv3CrGr-dQuLQ2IqB1faPN5uUj3gbvAS0W0000)

```
@startuml
Class Logger {
  + pushHandler(h: Handler\HandlerInterface)
  + popHandler(): Handler\HandlerInterface
}
Class Handler\StreamHandler
Class Handler\HandlerInterface
Logger -> Handler\HandlerInterface
Handler\HandlerInterface <|-- Handler\StreamHandler
@enduml
```

Logger 有些行為也正好是 Observer Pattern 的特色：

* 沒有 Handler 一樣能 work
* 可以動態追加或移除 Handler，Monolog 是使用 Array Stack 實作

使用 Observer Pattern 的好處很明確，實作儲存 log 的方法有千百種，加上寫 log 行為並不會太複雜（`info`、`error` 等），自從 PHP 有 PSR-3 後，行為又更加明確了。這樣的情境下使用 Observer Pattern 更能看出套用 Pattern 的好處。
