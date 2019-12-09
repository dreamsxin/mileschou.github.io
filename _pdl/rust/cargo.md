---
title: Cargo
description: Rust 學習筆記
layout: collections
---

Cargo 是一個類似 [Composer][] / [npm][] 的套件管理工具，同樣具備開發新專案的功能

比方說建一個 `helloworld2` 專案，可以這樣下指令

```
$ cd ~/projects
$ cargo new --bin helloworld2
```

其中 `cargo new` 是指建立新專案， `--bin` 是指要直接產生可執行檔，因為打算定義這是一個專案，而不是函式庫

接著裡面會產生兩個檔案，一個是專案的描述檔 `Cargo.toml` ，另一個是 HelloWorld 原始碼 `src/main.rs` 。進到專案目錄後再下 `cargo build` 會開始編譯，並產生執行檔；下 `cargo run` 會編譯並執行：

```
$ cargo build
   Compiling helloworld2 v0.1.0 (file://path/to/projects/helloworld2)
$ cargo run
     Running `target/debug/helloworld2`
Hello, world!
```

Cargo 會產生 target 目錄存放產出物，如執行檔。 git 可以直接把這個目錄忽略掉即可。

[Composer]: https://getcomposer.org/
[npm]: https://www.npmjs.com/
