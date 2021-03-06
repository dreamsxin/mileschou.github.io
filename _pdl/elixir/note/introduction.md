---
title: Introduction
layout: collections
---

## Installation

Mac 使用 brew

    brew install elixir

Docker 有[官方 repo](https://hub.docker.com/_/elixir)

    docker pull elixir

> 同時也會裝 [erlang](https://www.erlang.org/)。指令是 `erl`

## Tools

安裝完，會有主要指令 `elixir`、外帶 REPL 工具 `iex`、建置工具 `mix`。

`elixir` 後面可以接要執行的檔案，如：

```
$ echo 'IO.puts "Hello world"' > hello.exs
$ elixir hello.exs
Hello world
```

另外內建有幾個預設的 library 如下：

* Elixir - standard library
* EEx - templating library
* ExUnit - unit test library
* Logger - built-in Logger

## References

* https://stackoverflow.com/questions/36292620/elixir-when-to-use-ex-and-when-exs-files
