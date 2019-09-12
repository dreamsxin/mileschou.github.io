---
title: Monolog（3）－－Formatter 與 Handler 之間的關係
---

打開 Monolog 的資料夾，會發現除了昨天提到的 Logger 與 Handler 之外，還有幾個沒提到的角色，如 `Formatter` 或是 `Processor`。

今天我們就來看看 `Formatter` 裡面做了什麼事。

## 從使用它到了解它

首先當然先看看它如何使用！我們可以從先從 `Handler\HandlerInterface` 找到相關的實作：

```php
interface HandlerInterface
{
    public function setFormatter(FormatterInterface $formatter);
}

```

這裡可以注意到，它的設計是「抽象依賴抽象」，這符合[依賴反轉原則][SOLID 之 依賴反轉原則（Dependency inversion principle）]；並且它的行為設計上，是做成抽象與抽象之間的一對一關係（因為它用 `set`，而不是 `push`），所以它實際上是實作了 *Bridge Pattern*。關係圖如下：

![](http://www.plantuml.com/plantuml/png/SoWkIImgAStDuVBCAqajIajCJbNmICnBoKajYe7I28bgBWK5RONYr1At_ABSn1AWi4QQbGAS0rUeoLMBP1nSFWPJ9PTpJc9nCTn6v_oyvABKabGe7ogBC00c3nVXmkbMNJly5kFKQ5EZgulJGVYCXEZ4vrY7rBmKO5030000)

```
@startuml
Interface Handler\HandlerInterface {
  + setFormatter(f: FormatterInterface)
}
Interface Formatter\FormatterInterface
Class Handler\ConcreteHandler
Class Formatter\ConcreteFormatter
Handler\HandlerInterface -> Formatter\FormatterInterface
Handler\HandlerInterface <|-- Handler\ConcreteHandler
Formatter\FormatterInterface <|-- Formatter\ConcreteFormatter
@enduml
```

它們的實作之間並沒有直接耦合，而是透過抽象介面耦合；換句話說，只要物件有實作抽象介面的話，它就能正常的介接使用。

我們先來看昨天使用的 `Handler\StreamHandler` 裡面是使用了哪種 Formatter。追一下程式碼，會發現在 `Handler\AbstractHandler` 裡面：

```php
abstract class AbstractHandler implements HandlerInterface
{
    public function getFormatter()
    {
        if (!$this->formatter) {
            $this->formatter = $this->getDefaultFormatter();
        }

        return $this->formatter;
    }

    protected function getDefaultFormatter()
    {
        return new LineFormatter();
    }
}
```

因此預設會是 `LineFormatter`，當然不是發 Log 到 [Line](https://line.me/zh-hant/)，而是指單行的 log。

再來我們來寫一個測試程式如下：

```php
$logger = new \Monolog\Logger('name');

$handler = new \Monolog\Handler\StreamHandler('php://stdout', \Monolog\Logger::DEBUG);

$logger->pushHandler($handler);

$logger->warning('test');
```

這樣輸出的結果應該會如下：

```
[2018-01-15 18:10:12] name.WARNING: test [] []
```

剛有提到，我們應該能自由地抽換 Formatter 才對，我們來換成 `JsonFormatter` 試看看：

```php
$handler->setFormatter(new \Monolog\Formatter\JsonFormatter());
```

輸出就會變成 JSON 了：

```
{"message":"test","context":[],"level":300,"level_name":"WARNING","channel":"name","datetime":{"date":"2018-01-15 18:16:28.438148","timezone_type":3,"timezone":"UTC"},"extra":[]}
```

## 自由組合 1+1 = $50

相信大家都去過黃色拱門，Formatter 與 Handler 之間的關係事實上就跟銅板輕鬆點很像，可以依需求任意搭配兩區的餐點，而店員都可以接受並結帳。

我們也可以使用 Slack 配 Json 或是 Mail 配 Html 等等，完全自由配。

## 參考資料

* [SOLID 之 依賴反轉原則（Dependency inversion principle）][] - 看到 code 寫成這樣我也是醉了，不如試試重構？

[SOLID 之 依賴反轉原則（Dependency inversion principle）]: https://github.com/MilesChou/book-refactoring-30-days/blob/master/docs/day11.md
