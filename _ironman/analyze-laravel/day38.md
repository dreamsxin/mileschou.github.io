---
title: 分析 Collection（2）
---

以下先大概列幾個與原生 PHP 函式相關的方法：

| Native | Collection |
|---|---|
| array_chunk() | chunk() |
| array_combine() | combine() |
| array_diff() | diff() |
| array_flip() | flip() |
| array_filter() | filter() |
| array_map() | map() |
| array_reduce() | reduce() |
| array_slice() | slice() |
| array_walk() | each() |
 
通常 Collection 的實作，都有加強原生對 array 處理的方便性，這些就不多做說明。來提一些比較有趣的。

## `transform()`

這個方法跟 `map()` 其實是一樣的，但它會改變原本的物件的內容：

```php
public function transform(callable $callback)
{
    $this->items = $this->map($callback)->all();

    return $this;
}
```

## `pipe()`

這個 pipe 的意義，與 Bash 的 `|` 類似，把該物件交由 callback 處理

```php
public function pipe(callable $callback)
{
    return $callback($this);
}
```

## `tap()`

```php
public function tap(callable $callback)
{
    $callback(new static($this->items));

    return $this;
}
```

之前曾提過 `tap()` 函式。這個方法也是類似的概念，它的等價程式碼如下：

```php
$callback = function($items) {
    //
};

$collection->tap($callback);

tap($collection, $callback);
```

讓 collection 自帶 `tap()` 方法，會串聯方法或是語意，都會比原本的 `tap()` 函式來的好。

## `toBase()`

這個方法是用在繼承 Collection 的類別如 Eloquent Collection，如果想轉成單純的 Collection 的話，可以使用這個。

```php
public function toBase()
{
    return new self($this);
}
```

筆者也有自定義類別是繼承 Collection 的，不過設計上比較單純，所以還沒用過這個方法。

## `wrap()` 與 `unwrap()`

`wrap()` 會使用 Collection 把傳入的參數包裝起來，`unwrap()` 則是解包裝。

```php
public static function wrap($value)
{
    return $value instanceof self
        ? new static($value)
        : new static(Arr::wrap($value));
}

public static function unwrap($value)
{
    return $value instanceof self ? $value->all() : $value;
}
```

其中會注意到，`warp()` 裡面還用到了 `Arr::wrap()`，因此非 array 的參數也可以正常使用。

```php
// class Arr
public static function wrap($value)
{
    if (is_null($value)) {
        return [];
    }

    return ! is_array($value) ? [$value] : $value;
}
```

## `when()` 與 `unless()`

這兩個方法很有趣，`when()` 是當 $value 是 true 的時候，就會執行 callback；`unless()` 則相反。

```php
public function when($value, callable $callback, callable $default = null)
{
    if ($value) {
        // 如果 $value 是 true 就執行 callback
        return $callback($this, $value);
    } elseif ($default) {
        // 如果 $value 不是 true 且有 default callback 的話，就換執行 default callback 
        return $default($this, $value);
    }

    return $this;
}

public function unless($value, callable $callback, callable $default = null)
{
    return $this->when(! $value, $callback, $default);
}
```

可以注意到上面 `unless()` 寫法很有趣，它把 $value 反相後丟到 when，即可做出 unless 的方法。這特性在 Laravel 也很常見，比方說 `isEmpty()` 與 `isNotEmpty()`

```php
public function isEmpty()
{
    return empty($this->items);
}

public function isNotEmpty()
{
    return ! $this->isEmpty();
}
```

可以看到 `isNotEmpty()` 其實就是 `isEmpty()` 的相反。

會這樣設計的原因是：用起來比較直覺語意，可以參考下面兩段程式碼即可了解：

```php
if (!$collection->isEmpty()) {
    //
}

if ($collection->isNotEmpty()) {
    //
}
```

Laravel 框架很多設計都是環繞在直覺語意上的，非常值得參考。
