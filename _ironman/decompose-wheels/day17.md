---
title: Monolog（6）－－Handler 之間的關係
---

Handler 的繼承關係如下（使用 YAML 表示）：

```yaml
- HandlerInterface:
  - AbstractHandler:
    - AbstractProcessingHandler:
      - AbstractSyslogHandler:
        - SyslogHandler
        - SyslogUdpHandler
      - AmqpHandler
      - BrowserConsoleHandler
      - ChromePHPHandler
      - CouchDBHandler
      - CubeHandler
      - DoctrineCouchDBHandler
      - DynamoDbHandler
      - ElasticSearchHandler
      - ErrorLogHandler
      - FirePHPHandler
      - GelfHandler
      - IFTTTHandler
      - LogglyHandler
      - MailHandler:
        - MandrillHandler
        - NativeMailerHandler
        - SwiftMailerHandler
      - MongoDBHandler
      - NewRelicHandler
      - PHPConsoleHandler
      - RavenHandler
      - RedisHandler
      - RollbarHandler
      - SlackbotHandler
      - SlackWebhookHandler
      - SocketHandler:
        - FleepHookHandler
        - FlowdockHandler
        - HipChatHandler
        - LogEntriesHandler
        - PushoverHandler
        - SlackHandler
      - StreamHandler:
        - RotatingFileHandler
      - TestHandler
      - ZendMonitorHandler
    - BufferHandler:
      - DeduplicationHandler
    - FilterHandler
    - FingersCrossedHandler
    - GroupHandler:
      -  WhatFailureGroupHandler
    - NullHandler
    - PsrHandler
    - SamplingHandler
  - HandlerWrapper
```

洋洋灑灑列出一長串的 Class 名稱，大部分是單純實作服務的串接，有另一小部分的 Handler 是有特殊用途的，撿幾個來介紹。

## TestHandler

這個 Handler 是設計用來做測試的，比方說：

```php
$logger = new \Monolog\Logger('name');

$handler = new \Monolog\Handler\TestHandler();

$logger->pushHandler($handler);

$logger->warning('test');

var_dump($handler->hasAlertRecords());
var_dump($handler->hasWarningRecords());
```

這樣輸出的結果會是：

```php
bool(false)
bool(true)
```

它可以作為一個 spy，去確認寫到 Logger 的內容是正確的。

它的設計方法也很單純，在 write 去寫入一個陣列：

```php
protected function write(array $record)
{
    $this->recordsByLevel[$record['level']][] = $record;
    $this->records[] = $record;
}
``` 

而在 assertion 的方法去找陣列有沒有對應的值即可，非常厲害。

## GroupHandler

這可以把多個 Handler 集合成一個 Group，而對這個 Group 操作，就等於對全部的 Handler 操作。

## NullHandler

它的說明很有趣：

> Blackhole

所有的 Log 將會像是遇到無底洞一樣，全部被這個 Handler 吃光光。

這也是設計用來測試用的。

## PsrHandler

覺得 Monolog 不好，但有中意其他 PSR Logger。雖然傷心寂寞覺得冷，但還是可以考慮用 Monolog 的 PsrHandler 包裝其他 PSR Logger 哦。
