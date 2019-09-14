---
title: Arr 的版本差異
layout: collections
tags: [Laravel]
---


## `first()`、`last()`、`where()` 的調整

Laravel 5.2 的 [`Arr::first()`](https://github.com/laravel/framework/blob/v5.2.45/src/Illuminate/Support/Arr.php#L163-L165) 在呼叫 callback 的時候，第一個參數是 key，第二個參數是 value：

```php
if (call_user_func($callback, $key, $value)) {
    return $value;
}
```

而從 Laravel 5.3 開始，[`Arr::first()`](https://github.com/laravel/framework/blob/v5.3.31/src/Illuminate/Support/Arr.php#L147-L149) 改為，第一個參數是 value，第二個參數是 key：

```php
if (call_user_func($callback, $value, $key)) {
    return $value;
}
```

> 參考[官方文件](https://laravel.com/docs/5.3/upgrade#upgrade-5.3.0)。
