---
title: Getting Started
layout: collections
---

Elixir 內建一個工具叫 Mix，它可以方便地建立新的 project。

使用 `mix new` 指令：

```
$ mix new some_project
* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
* creating lib
* creating lib/some_project.ex
* creating test
* creating test/test_helper.exs
* creating test/some_project_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd some_project
    mix test

Run "mix help" for more commands.
```

檔案的用途如下：

```yaml
- config: 
  - config.exs              # 各位 package 的設定，可以看裡面的說明
- lib:                      # 實作的程式放這裡
  - some_project.ex         # 預設的空實作
- mix.exs                   # Mix 設定，包括名稱、版本、依賴等，這也是 mix 指令用來執行任務的設定
- test:                     # 單元測試
  - test_helper.exs         # 預設只有一行啟動程式碼，這個功能類似 bootstrap
  - some_project_test.exs   # 此測試對應 sample.ex 的實作
```

訊息裡面有提到，可以進入 project 下 `mix test`，這是做單元測試：

```
$ mix test

Compiling 1 file (.ex)
Generated some_project app
..

Finished in 0.07 seconds
1 doctest, 1 test, 0 failures

Randomized with seed 747188
```

試一下改程式，修改 `some_project.ex` 檔：

```elixir
defmodule SomeProject do
  def hello do
    IO.puts "hello world"
  end
end
```

使用 `mix compile` 編譯檔案，再使用 `iex -S mix` 進入 REPL 測試：

```
* iex -S mix

Erlang/OTP 21 [erts-10.3] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe] [dtrace]

Interactive Elixir (1.8.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> SomeProject.hello 
hello world
:ok
iex(2)>
```

再來寫一下單元測試：

```elixir
defmodule SomeProjectTest do
  use ExUnit.Case

  test "case1" do
    assert :ok = SomeProject.hello
  end
end
```

跑一下測試 `mix test` 即可。

如果要編譯成二進位檔執行的話，首先要先調整執行的過程。得先改成有 main method 與參數：

```elixir
def main(args \\ []) do
  IO.puts "hello world"
  IO.puts args
end
```

再來調整 `mix.exs` 設定：

```elixir
  def project do
    [
      app: :lyrae_elixir,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  defp escript do
    [main_module: SomeProject]
  end
```

接著執行 `mix escript.build`，即可產出可執行檔，名稱跟專案同名 `some_project`，執行即可看到結果

```
$ ./some_project
hello world
```

## References

* [Executables](https://elixirschool.com/en/lessons/advanced/escripts/) | Elixir School
