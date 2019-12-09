---
title: Documentation
layout: collections
---

## `@spec`

`@spec` 可以類似定義介面一樣，定義函數的輸入輸出，下面是一個簡單的範例：

```elixir
defmodule My do
  @spec sum(integer, integer) :: integer
  def sum(a, b) do
    a + b
  end
end

# 3
IO.puts My.sum(1, 2)

# (ArithmeticError) bad argument in arithmetic expression: 1 + "2"
IO.puts My.sum(1, "2")
```

> 因為 Elixir 是動態語言，要到執行階段才會丟 `ArithmeticError` 錯誤。

## `@type`

單純的輸入輸出下，`@spec` 即可運作良好，但如果複雜結構的話，就得接助 `@type`。`@type` 可以自定義型別，並使用在 `@spec` 上。下面是一個簡單的範例：

```elixir
defmodule People do
  @type t(name, age) :: %People{name: name, age: age}
  @type t :: %People{name: charlist, age: integer}
  defstruct name: nil, age: nil
end

defmodule Some do
  def run do
    a = %People{name: "some"}
    IO.puts a.name
    IO.puts a.age
  end
end

Some.run()
```

與 `@spec` 不同的是，定義型別對在某些情況下，並不會有約束力，但可以讓 IDE 工具使用。

## References

* [Dialyzer](https://erlang.org/doc/man/dialyzer.html) | 靜態分析工具
* [Dialyxir](https://github.com/jeremyjh/dialyxir) | Mix 裡，方便地用 Dialyzer 套件
