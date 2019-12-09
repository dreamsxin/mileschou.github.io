---
title: Pipe Operator
layout: collections
---

函式的連續呼叫，可能會造成程式混亂。比方說有下面這段程式：

```elixir
defmodule Math do
  def inc(x), do: x + 1
  def dec(x), do: x - 1
  def sum(x, y), do: x + y
end
```

若想要連續加三次，一般的語言會這麼寫：

```elixir
# 13
IO.puts inc(inc(inc(10)))
```

這種寫法容易造成閱讀上的困擾。Elixir 提供了一個特別的運算字－－管線運算子 `|>`，來解決這個問題。上面的寫法等價於下面的寫法：

```elixir
IO.puts 10 |> inc() |> inc() |> inc()
```

它的作法是，把 `|>` 左邊的結果，送給右邊當作是第一個參數傳入，然後依續執行到右邊。

## 實例

> [參考](https://elixirschool.com/zh-hant/lessons/basics/pipe-operator/)

轉大寫並切割字串

```
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

## 多引數

如果有多引數，雖然不是必要，但 Elixir 會建議要使用括號，這對維護性是有幫助的。

```elixir
0 |> inc() |> sum 10 |> inc() |> inc()
0 |> inc() |> sum(10) |> inc() |> inc()
```

上面這兩個結果是一樣的，但第一個會出現下面的警告：

```
warning: parentheses are required when piping into a function call. For example:

    foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

    foo(1) |> bar(2) |> baz(3)
```
