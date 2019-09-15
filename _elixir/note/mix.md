---
title: Mix
layout: collections
---

Mix 是一個多種開發的工具集合為一體的工具組，使用 `mix help` 可以查看所有指令：

```
mix                   # Runs the default task (current: "mix run")
mix app.start         # Starts all registered apps
mix app.tree          # Prints the application tree
mix archive           # Lists installed archives
mix archive.build     # Archives this project into a .ez file
mix archive.install   # Installs an archive locally
mix archive.uninstall # Uninstalls archives
mix clean             # Deletes generated application files
mix cmd               # Executes the given command
mix compile           # Compiles source files
mix deps              # Lists dependencies and their status
mix deps.clean        # Deletes the given dependencies' files
mix deps.compile      # Compiles dependencies
mix deps.get          # Gets all out of date dependencies
mix deps.tree         # Prints the dependency tree
mix deps.unlock       # Unlocks the given dependencies
mix deps.update       # Updates the given dependencies
mix do                # Executes the tasks separated by comma
mix escript           # Lists installed escripts
mix escript.build     # Builds an escript for the project
mix escript.install   # Installs an escript locally
mix escript.uninstall # Uninstalls escripts
mix format            # Formats the given files/patterns
mix help              # Prints help information for tasks
mix hex               # Prints Hex help information
mix hex.audit         # Shows retired Hex deps for the current project
mix hex.build         # Builds a new package version locally
mix hex.config        # Reads, updates or deletes local Hex config
mix hex.docs          # Fetches or opens documentation of a package
mix hex.info          # Prints Hex information
mix hex.organization  # Manages Hex.pm organizations
mix hex.outdated      # Shows outdated Hex deps for the current project
mix hex.owner         # Manages Hex package ownership
mix hex.publish       # Publishes a new package version
mix hex.repo          # Manages Hex repositories
mix hex.retire        # Retires a package version
mix hex.search        # Searches for package names
mix hex.user          # Manages your Hex user account
mix loadconfig        # Loads and persists the given configuration
mix local             # Lists local tasks
mix local.hex         # Installs Hex locally
mix local.public_keys # Manages public keys
mix local.rebar       # Installs Rebar locally
mix new               # Creates a new Elixir project
mix profile.cprof     # Profiles the given file or expression with cprof
mix profile.eprof     # Profiles the given file or expression with eprof
mix profile.fprof     # Profiles the given file or expression with fprof
mix run               # Starts and runs the current application
mix test              # Runs a project's tests
mix xref              # Performs cross reference checks
iex -S mix            # Starts IEx and runs the default task
```

## Hex 與 Rebar

在使用過程中，可能會提醒要裝兩個東西，一個是 Hex，另一個是 Rebar（指的是 [Rebar3](http://www.rebar3.org/)）。

> [Rebar](https://github.com/rebar/rebar) 是一個被廢棄的專案，目前講 Rebar 大多都是指 Rebar3。

對應的安裝指令如下：

```
mix local.hex         # Installs Hex locally
mix local.rebar       # Installs Rebar locally
```

[Hex](https://hex.pm/) 是 Erlang 生態系的套件管理中心，上面可以找到非常多 Erlang 的套件。Rebar 跟 Mix 一樣，是 build tool，但它是設計給 Erlang 用的。

它們之間的關係是：Elixir + Mix 或 Erlang + Rebar 都能使用並下載 Hex 上的套件庫。但因為 Elixir 設計成可以很容易取用 Erlang 的功能或套件（如 Hex 上下載的），所以為了要建構 Erlang 的專案，則必須要依賴 Rebar 建置。

另外，Erlang 之於 Hex 的關係，蠻像 [PHP](https://www.php.net/) 之於 [Composer](https://getcomposer.org/)：有 Hex 或 Composer 會很方便，但都不是必要下載的工具。

> [Hex 原始碼](https://github.com/hexpm/hex)

### 引用 Hex 套件

與 PHP + Composer 不大一樣的是，Mix 並沒有提供指令引用套件的功能，必須得採用修改設定檔 `mix.exs` 的方法達成。

比方說要引用 [Phoenix](https://hex.pm/packages/phoenix)，可以在下面的 `deps` 區塊加入引用的 Tuple：

```elixir
defmodule SomeProject.MixProject do
  defp deps do
    [
      {:phoenix, "~> 1.4"}
    ]
  end
end
```

> 依賴的寫法也有細節，不過這裡先省略。

當定義好後，就可以執行下載依賴的 Mix 指令：

```
mix deps.get
```

下載完後，與大部分的依賴管理系統類似，會產生一個鎖定版本的檔案叫 `mix.lock`。這個檔要不要 commit 進版控，跟一般的 lock 檔概念相同，看軟體性質是 lib 還是 project 而定。

## 編譯（compile）

Elixir 的檔案分為 `.ex` 與 `.exs` 兩種，前者是需要編譯的檔案，如 `lib` 裡面的主程式；後者則是可以當成腳本執行，所以包括 Mix 設定、單元測試等，都是 .exs。

如果要編譯程式的話，可以下這個指令：

```
mix compile
```

## 系統環境（environments）

Mix 在執行的時候，可以帶入使用環境，預設有三種環境：

* `:dev` 預設使用環境
* `:test` 在 `mix test` 的時候，會使用這個環境。
* `:prod` 用在把程式交到正式部署環境

若要存取目前的環境，可以使用 `Mix.env`，而執行指令只要帶 `MIX_ENV` 的環境變數即可：

```
MIX_ENV=prod mix compile
```

## Phases

類似 hook，Mix 也有類似的機制，稱之為 Phases，應用程式會照內定的順序執行不同的 Phases。若沒有自定義 Phases 要執行的內容，則會跳過該 Phases。

看官方的例子 `MyApp.application/0`

```elixir
def application do
  [start_phases: [init: [], go: [], finish: []],
   included_applications: [:my_included_app]]
end
```

`mix.exs` 另外還有定義 `:my_included_app`，是一個引用的應用程式：

```elixir
def application do
  [mod: {MyIncludedApp, []},
   start_phases: [go: []]]
end
```

在這個例子裡，下面是呼叫 callback 的順序：

```elixir
Application.start(MyApp)
MyApp.start(:normal, [])
MyApp.start_phase(:init, :normal, [])
MyApp.start_phase(:go, :normal, [])
MyIncludedApp.start_phase(:go, :normal, [])
MyApp.start_phase(:finish, :normal, [])```
```
