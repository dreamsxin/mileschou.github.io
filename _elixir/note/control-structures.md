---
title: Control Structures
layout: collections
---

## if 與 unless

一般的語言，`if` 可說是經典的流程控制的關鍵字，但 Elixir 裡，它是 macro！（[原始碼參考](https://github.com/elixir-lang/elixir/blob/v1.8.1/lib/elixir/lib/kernel.ex#L2995)）

從原始碼也可以找得到，`if/2` 屬於 falsey 只有 `nil` 與 `false`。舉個例，下面所有的 `IO.puts/1` 都會被執行：

```elixir
if true do
  IO.puts "if true"
end

if :true do
  IO.puts "if :true"
end

if [] do
  IO.puts "if []"
end

unless false do
  IO.puts "unless false"
end

unless :false do
  IO.puts "unless :false"
end

unless nil do
  IO.puts "unless nil"
end

unless :nil do
  IO.puts "unless :nil"
end
```

`else` 也支援：  

```elixir
if false do
  IO.puts "nothing"
else
  IO.puts "if else"
end
```

但，它並沒有 `else if` 的用法。

## case

`case/2` 可以做多種模式的比對，有點類似函數的模式比對：

```elixir
# ok pattern
{:ok} -> IO.puts "Success"
# ok 並帶有 result 的 pattern
{:ok, result} -> IO.puts "Success and result: " <> result
# error pattern
{:error} -> IO.puts "ERROR!"
```

也可以做變數綁定

```elixir
case {1, 2, 3} do
  # 比對到就會綁定值
  {1, x, y} -> IO.puts x + y
  _ -> IO.puts "Nothing match"
end

# 5
```

也可以使用 pin 運算子鎖值

```elixir
x = 10

case {1, 2, 3} do
  # 因 x 值被固定在 10，所以這個比對不到
  {1, ^x, y} -> IO.puts x + y

  # 會比對到這個
  _ -> IO.puts "Nothing match"
end
```

如果都沒比對到的話，會丟 `CaseClauseError` 執行階段錯誤，像下面這個

```elixir
case :ok do
  :error -> "Won't match"
end
```

如果想要有預設的比對，可以用 `_`，如前一個例子所示。

`case/2` 也支援監視 (guard) 子句（官方範例）：

```elixir
case {1, 2, 3} do
  {1, x, 3} when x > 0 ->
    IO.puts "Will match"
  _ ->
    IO.puts "Won't match"
end

# "Will match"
```

## cond

如果不是要比對模式，而是要比對條件（conditions）的話，可以使用 `cond/1`，這就跟其他語言的 `else if` 類似。

```elixir
cond do
  2 + 2 == 5 ->
    IO.puts "This will not be true"
  2 * 2 == 3 ->
    IO.puts "Nor this"
  1 + 1 == 2 ->
    IO.puts "But this will"
end

# But this will
```

判斷的方法跟 `if/2` 一樣，只要不是 `nil` 或 `false` 就是 `true`

與 `case/2` 類似地，如果所有條件都是 false 時，會出現 `CondClauseError` 執行錯誤，如下面這個寫法：

```elixir
cond do
  2 * 2 == 3 -> IO.puts "Nothing match"
end
```

如果想要保證一定會有成功的比對，可以最後加 true 的條件：

```elixir
cond do
  2 * 2 == 3 -> IO.puts "Nothing match"
  true -> IO.puts "Will match"
end
```

## with

如果有一連串的比對，使用 `with/1` 是一個不錯的選擇。`with/1` 的做法是拿 `<-` 的右側來跟左邊做比對，下面是一個 ok 的例子：

```elixir
user = %{first: "Sean", last: "Callan"}

IO.puts with {:ok, first} <- Map.fetch(user, :first),
             {:ok, last} <- Map.fetch(user, :last),
             do: last <> ", " <> first
```

若是失敗則會回傳 `:error`

```elixir
user = %{last: "Callan"}

IO.puts with {:ok, first} <- Map.fetch(user, :first),
             {:ok, last} <- Map.fetch(user, :last),
             do: last <> ", " <> first

# error
```

這語法有助於把巢狀的判斷改成一連串的判斷。
