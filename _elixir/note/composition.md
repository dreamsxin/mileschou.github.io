---
title: Composition
layout: collections
---

Composition 指的是模組（module）間互相引用的行為。Elixir 有提供四種方法來組合模組，概觀如下：

```elixir
# Alias 允許使用 Bar 來取代全名 Foo.Bar
alias Foo.Bar, as: Bar

# Require 允許使用 Foo 的巨集
require Foo

# Import Foo 裡面的所有函式，這樣呼叫就不用再打 Foo 了。
import Foo

# Use 巨集
use Foo
```

## `alias`

別名（alias）可以讓我們在模組裡，使用較簡單的名稱來取代其他模組的全名：

```elixir
defmodule Math.Foo do
  def sum(x, y), do: x + y
end

defmodule Context do
  alias Math.Foo

  # 使用 alias 呼叫 Math.Foo
  def add(x, y), do: Foo.sum(x, y)

  # 使用模組的全名呼叫 Math.Foo
  def addWithFullName(x, y), do: Math.Foo.sum(x, y)
end

IO.puts Context.add(2, 3)
IO.puts Context.addWithFullName(2, 3)
```

`alias/1` 預設會使用最後面的名稱當作是別名，以此範例而言，會是 `Foo`。

> 跟常見的 Java、PHP 等一樣。

若是 `alias/2`，則第二個參數可以代入 `as: something`，來取代成自定義的名稱，或是避免衝突：

```elixir
defmodule Math.Foo do
  def sum(x, y), do: x + y
end

defmodule Context do
  # 自定義別名
  alias Math.Foo, as: Bar

  def add(x, y), do: Bar.sum(x, y)
end

IO.puts Context.add(2, 3)
```

另外，也有一次引用多個模組的寫法

```elixir
defmodule Math.Foo do
  def sum(x, y), do: x + y
end

defmodule Math.Bar do
  def inc(x), do: x + 1
end

defmodule Context do
  # 一次引用多個模組
  alias Math.{Foo, Bar}

  def add(x, y), do: Foo.sum(x, y)
  def ipp(x), do: Bar.inc(x)
end

IO.puts Context.add(2, 3)
IO.puts Context.ipp(2)
```

## `require`

require 可以用在導入巨集，而沒辦法導入函數：

```elixir
defmodule Math do
  require SuperMath

  SuperMath.super_sum
end
```

## `import`

import 是用在導入函數，如：

```elixir
defmodule Math.Foo do
  def sum(x, y), do: x + y
end

defmodule Context do
  # 導入 Math.Foo 的所有 function
  import Math.Foo

  def add(x, y), do: sum(x, y)
end

IO.puts Context.add(2, 3)
```

import 也可以使用 `only:` 導入部分，如：

```elixir
defmodule Math.Foo do
  def sum(x, y), do: x + y
  def mux(x, y), do: x * y
end

defmodule Context do
  # 只導入 Math.Foo 的 sum/2 function
  import Math.Foo, only: [sum: 2]

  # 這行會炸，因為沒有 mux
  # def m(x, y), do: mux(x, y)
end
```

另外也有反相操作的 `except:`

```elixir
defmodule Math.Foo do
  def sum(x, y), do: x + y
  def mux(x, y), do: x * y
end

defmodule Context do
  # 導入 Math.Foo 除了 sum/2 以外的所有 function
  import Math.Foo, except: [sum: 1]

  # 這行會炸，因為沒有 sum
  # def m(x, y), do: sum(x, y)
end
````

另外有兩個特殊 atom，`:functions` 和 `:macros`，它們分別只導入函數或巨集：

```elixir
import Math.Foo, only: :functions
import Math.Foo, only: :macros
```

## `use`

`use` 可以讓另一個模組來修改本模組的 **定義**。當使用 `use`，實際上會呼叫該模組的 `__using__/1` 巨集，巨集的結果就會成為模組定義的一部分。

參考下面這個簡單的例子：

```elixir
defmodule Hello do
  defmacro __using__(_opts) do
    quote do
      def hello(name), do: "Hi, #{name}"
    end
  end
end

defmodule Example do
  use Hello
end

# Hi, Sean
IO.puts Example.hello("Sean")
```

> 這裡多了幾個關鍵字 `defmacro`、`quote` 等，是定義巨集用的。

`__using__/1` 還會傳另外的參數，參考下面這個例子：

```elixir
defmodule Hello do
  defmacro __using__(opts) do
    # 如果有給 greeting 的話，就用，沒有的話，預設是 Hi
    greeting = Keyword.get(opts, :greeting, "Hi")

    quote do
      def hello(name), do: unquote(greeting) <> ", " <> name
    end
  end
end

defmodule Example do
  # 把 Hi 換掉
  use Hello, greeting: "Hola"
end

# Hola, Sean
IO.puts Example.hello("Sean")
```

這是簡單的 `use` 實作範例，而使用上，最常見的就是單元測試：

```elixir
use ExUnit.Case, async: true
```

它對應的原始碼在[這裡](https://github.com/elixir-lang/elixir/blob/v1.8.1/lib/ex_unit/lib/ex_unit/case.ex#L211)。看完上面的範例，相信知道它大概在做什麼了。

### 被 use 的模組，`__using/1` 是必須存在的

下面這個範例是不能用的：

```elixir
defmodule Hello do
  defmacro __using__() do
    quote do
      def hello(name), do: "Hi, #{name}"
    end
  end
end

defmodule Example do
  # 它會說找不到 __using__/1
  use Hello
end
```

除了一定要存在外，也必須是巨集才會有效：

```elixir
defmodule Hello do
  def __using__(opt) do
    quote do
      def hello(name), do: "Hi, #{name}"
    end
  end
end

defmodule Example do
  use Hello
end

# 上面的語法雖然沒有問題，但 __using 若不是 macro，想要導進來的函數就會無效。
Example4.hello("Sean")
```

## References

* https://elixir-lang.org/getting-started/alias-require-and-import.html
* https://elixirschool.com/en/lessons/basics/modules/#composition