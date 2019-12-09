---
title: Functions
layout: collections
---

Elixir 的函數（function）跟大多數流行語言一樣，也是一等公民（first class citizens），這代表函數可以當成是變數一樣地傳遞。

## 匿名函數（Anonymous Functions）

正如其名，這個函數是沒有名字的。要定義一個匿名函數，會使用 `fn` 與 `end` 關鍵字。定義與呼叫的範例如下：

```elixir
sum = fn (x, y) -> x + y end

IO.puts sum.(2, 3) # 5
```

它也有簡寫的寫法：

```elixir
sum = &(&1 + &2)

IO.puts sum.(2, 3) # 5
```

其中裡面的 `&1` 與 `&2` 代表的是第一個參數與第二個參數。

## 模式比對（Pattern Matching）

Elixir 的模式比對除了用在變數外，也可以用在函數的 signatures 上。這功能就類似 Java 的多載（overload）有多種 signatures 一樣，但又比多載有著不同方向的彈性。舉例如下：

```elixir
handler = fn
  # ok pattern
  {:ok} -> IO.puts "Success"

  # ok 並帶有 result 的 pattern
  {:ok, result} -> IO.puts "Success and result: " <> result

  # error pattern
  {:error} -> IO.puts "ERROR!"
end

handler.({:ok})
handler.({:ok, "some result"})
handler.({:error})
```

上面三個傳入值，依續會比對上面三種 pattern。比對是有順序的，會由上而下比對，若寫不好就有可能會有 pattern 永遠進不去，不過 Elixir 會出現 warning 提醒：

```elixir
some = fn
  # ok 並帶有 result 的 pattern
  {:ok, result} -> IO.puts "Success and result: " <> result

  # 這個 pattern 永遠進不來
  {:ok, something} -> IO.puts "Nooooooooo!"
end

some.({:ok, "some result"})
```

## 命名函數（Named Functions）

命名函數必須要「住」在 module 下，函數定義的方法是使用 `def` 巨集（另外有一個是私有函數，使用 `defp`），先看簡單的定義：

```elixir
defmodule Math do
  def context do
    sum(2, 3)
  end

  def sum(x, y) do
    x + y
  end
end

IO.puts Math.sum(2, 3) # 5
IO.puts Math.context() # 5
```

不管是從外部呼叫，或是從 context() 做內部呼叫，都是可以正常執行的。

這裡可以發現匿名函數與命名函數的呼叫差異：呼叫匿名函數時，使用點（`.`）和括號是絕對必要的。這樣能明確區分匿名函數與命名函數。看下面這個組合例子：

```elixir
defmodule Math do
  def context do
    # sum 是存放匿名函數的變數
    sum = getFn()

    # 這個 sum 是呼叫命名函數
    IO.puts sum(2, 3)

    # 這個 sum 是呼叫匿名函數
    IO.puts sum.(2, 3)

    # 呼叫命名函數與呼叫匿名函數也可以串在一起
    IO.puts getFn().(2, 3)
  end

  def sum(x, y), do: x + y

  def getFn(), do: fn (x, y) -> x + y end
end

# 因呼叫三次 sum，所以會有三個 5
Math.context() 
```

> 不一定每個語言都有辨認上的問題，如 PHP 的變數需要 `$` 所以容易區分；而 Go 或 Javascript 可能就會比較難區別。

### 函數命名

Elixir 的世界裡，是使用「函數名」 + 「引數的數量」來辨別不同函數的。我們可以使用 `Function.info/1` 來查看函數細節；另外也可以用 `&` 來轉換現有的命名函數為變數。舉個例子：

```
iex> Function.info(&apply/1)
** (CompileError) iex:11: undefined function apply/1
iex> Function.info(&apply/2)
[module: :erlang, name: :apply, arity: 2, env: [], type: :external]
iex> Function.info(&apply/3)
[module: :erlang, name: :apply, arity: 3, env: [], type: :external]

iex> is_function &apply/1
** (CompileError) iex:12: undefined function apply/1
iex> is_function &apply/2
true
iex> is_function &apply/2
true
iex> is_function &apply/2, 1
false
iex> is_function &apply/2, 2
true
iex> is_function &apply/3
true
```

從這個例子可以理解 `apply/1`、`apply/2` 與 `apply/3` 是三個不同的函數。其中 `is_function/2` 的第二個參數，是確認這個函數是否有 n 個引數，所以 `apply/2` 要傳 2 進去，才會回傳 true。

而這跟函數多載（overload）是不同的，在 Elixir 裡，會認為這些是不同的函數。像模式比對只會對相同數量的引數有效，因此下面這個定義是不合法的：

```elixir
handler = fn
  (:ok, result) -> IO.puts "Success and result: " <> result

  {:ok, result} -> IO.puts "Success and result: " <> result
end
```

反之，我們是可以這樣定義的：

```elixir
defmodule Math do
  def sum(), do: 0
  def sum(x), do: x
  def sum(x, y), do: x + y
end

IO.puts Math.sum()          # 0
IO.puts Math.sum(10)        # 10
IO.puts Math.sum(10, 20)    # 30
```
