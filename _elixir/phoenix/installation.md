---
title: Installation
layout: collections
---

Phoenix 使用 Elixir 1.5+ 撰寫，所以需要相關的依賴，包括 Erlang 18+。

```
$ elixir -v
Erlang/OTP 21 [erts-10.3] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe] [dtrace]

Elixir 1.8.1 (compiled with Erlang/OTP 21)
```

而 Phoenix 相關的程式碼，會需要透過 Hex 下載，所以必須先安裝 Hex：

```
mix local.hex
```

接著再從 Hex 下載 Phoenix archive：

```
mix archive.install hex phx_new 1.4.3
```

裝完後，Mix 將會多下面幾個指令：

```
mix phx.new           # Creates a new Phoenix v1.4.3 application
mix phx.new.ecto      # Creates a new Ecto project within an umbrella project
mix phx.new.web       # Creates a new Phoenix web project within an umbrella project
```

## Initial Project

使用 `phx.new` 或 `phx.new.web` 差異不大，只差前者是全新專案，後者則是用在 [Umbrella Project](/docs/umbrella-projects.md) 下。

此外，如果不需要用 Ecto，可以加上 `--no-ecto` 參數；不需要 Webpack，可以加上 `--no-webpack` 參數。

> [參考](https://hexdocs.pm/phoenix/phoenix_mix_tasks.html#mix-phx-new)

這是建立一個 newbie 專案的歷程，因單純只是新手練習，所以把 Ecto 和 Webpack 都先移除

```
$ mix phx.new newbie --no-ecto --no-webpack
* creating newbie/config/config.exs
* creating newbie/config/dev.exs
* creating newbie/config/prod.exs
* creating newbie/config/prod.secret.exs
* creating newbie/config/test.exs
* creating newbie/lib/newbie/application.ex
* creating newbie/lib/newbie.ex
* creating newbie/lib/newbie_web/channels/user_socket.ex
* creating newbie/lib/newbie_web/views/error_helpers.ex
* creating newbie/lib/newbie_web/views/error_view.ex
* creating newbie/lib/newbie_web/endpoint.ex
* creating newbie/lib/newbie_web/router.ex
* creating newbie/lib/newbie_web.ex
* creating newbie/mix.exs
* creating newbie/README.md
* creating newbie/.formatter.exs
* creating newbie/.gitignore
* creating newbie/test/support/channel_case.ex
* creating newbie/test/support/conn_case.ex
* creating newbie/test/test_helper.exs
* creating newbie/test/newbie_web/views/error_view_test.exs
* creating newbie/lib/newbie_web/gettext.ex
* creating newbie/priv/gettext/en/LC_MESSAGES/errors.po
* creating newbie/priv/gettext/errors.pot
* creating newbie/lib/newbie_web/controllers/page_controller.ex
* creating newbie/lib/newbie_web/templates/layout/app.html.eex
* creating newbie/lib/newbie_web/templates/page/index.html.eex
* creating newbie/lib/newbie_web/views/layout_view.ex
* creating newbie/lib/newbie_web/views/page_view.ex
* creating newbie/test/newbie_web/controllers/page_controller_test.exs
* creating newbie/test/newbie_web/views/layout_view_test.exs
* creating newbie/test/newbie_web/views/page_view_test.exs
* creating newbie/priv/static/css/app.css
* creating newbie/priv/static/css/phoenix.css
* creating newbie/priv/static/js/app.js
* creating newbie/priv/static/robots.txt
* creating newbie/priv/static/js/phoenix.js
* creating newbie/priv/static/images/phoenix.png
* creating newbie/priv/static/favicon.ico

Fetch and install dependencies? [Yn] Y
* running mix deps.get
* running mix deps.compile

We are almost there! The following steps are missing:

    $ cd newbie

Start your Phoenix app with:

    $ mix phx.server

You can also run your app inside IEx (Interactive Elixir) as:

    $ iex -S mix phx.server
```