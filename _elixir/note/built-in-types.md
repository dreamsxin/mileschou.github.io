---
title: Built-in Types
layout: collections
---

> 使用 `iex` + `i/1` 做說明

內建的資料型態有下面這些（名稱序）

* Atom
* Float
* Function
* Integer
* List
* Map
* Process
* Port
* Tuple

## Integer

[Integer](https://hexdocs.pm/elixir/Integer.html) 很單純，就是一般所知道的整數，除了十進位表示法之外，也可以用二進位、八進位與十六進位表示：

```
iex> 255
255
iex> 0b11111111
255
iex> 0o377
255
iex> 0xFF
255
```

Elixir 使用大數運算，所以不像有的語言（如 PHP）會受到機器處理位元數的限制。

## Float

[Float](https://hexdocs.pm/elixir/Float.html) 預設使用 64 bit 雙精度，也可以使用科學記號 `e` 表示指數：

```
iex> 3.14
3.14
iex> 3.14e-10
3.14e-10
```

如大多數語言一樣，會有精準度問題。

## Atom

[Atom](https://hexdocs.pm/elixir/Atom.html) 使用一個名字來表示實字常數（包括 `true`、`false` 與 `nil`）

```
iex> is_atom(false)
true
iex> is_boolean(:false)
true
iex> :false === false
true
```

> 與 Ruby 的 `Symbol` 意義是相同的。

Module 名稱也是 Atom 即便沒被宣告過 

```
iex(16)> is_atom(Some.Module)
true
```

## References

* https://hexdocs.pm/elixir/Kernel.html
