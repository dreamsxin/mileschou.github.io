---
title: Carbon（1）－－PHP 世界的時光機
---

[時間旅行][]一直以來都是電影或動漫的經典主題；時間處理也是－－它是程式語言的經典卡關問題。

[Carbon][] 是 PHP 的第三方時間處理套件。它繼承了原生的 Datatime，並新增了許多語意化的行為，讓處理時間的難度降低許多。

比方說：想像自己是未來世界的[特南克斯][]，乘坐的時光機程式是用 PHP 寫的，那該如何知道 20 年前的 timestamp 呢？

讓 Carbon 來處理就很簡單：

```php
use Carbon\Carbon;

echo Carbon::now('Asia/Tokyo')->subYears(20)->timestamp;
```

或是維斯在黃金弗利沙毀滅地球的時候，決定出手倒退時光。那他怎麼定位出三分鐘前的時間點呢？

對 Carbon 來說只是小菜一碟：

```php
use Carbon\Carbon;

echo Carbon::now('Asia/Tokyo')->subMinutes(3)->timestamp;
```

## 為何用 Carbon

總括來說，Carbon 處理了下面的問題：

1.  語意化的取值方法，如：

    ```php
    Carbon::now();        // 現在
    Carbon::today();      // 今天 00:00:00
    Carbon::tomorrow();   // 明天 00:00:00
    ```

2.  語意化的比較方法，如：

    ```php
    $time1->lessThan($time2);          // $time1 是否比 $time2 早
    $time1->closest($time2, $time3);   // 取得離 $time1 比較近的時間
    $time1->isWeekend();               // $time1 是週末嗎
    ```

3.  頭痛的時區問題

    ```php
    echo Carbon::now('Asia/Taipei');
    echo Carbon::now('Asia/Tokyo');

    // 兩個時間會差一小時
    ```

明天就來看看 Carbon 是如何解決這些問題的。

## 參考資料

* [Carbon][]
* [時間旅行][]
* [特南克斯][]

[特南克斯]: https://zh.wikipedia.org/wiki/%E7%89%B9%E5%8D%97%E5%85%8B%E6%96%AF
[Carbon]: https://github.com/briannesbitt/Carbon
[時間旅行]: https://zh.wikipedia.org/wiki/%E6%97%B6%E9%97%B4%E6%97%85%E8%A1%8C
