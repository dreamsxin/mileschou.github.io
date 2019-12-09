---
title: 環境安裝
description: Rust 學習筆記
layout: collections
---

安裝方法簡單介紹幾種

## Mac

使用 Homebrew 安裝

```
brew update
brew install rust

# Install completion
brew install rust-completion
brew install cargo-completion
```

## Docker

Based on Debian

```dockerfile
FROM debian:jessie

ENV BUILD_DEPS \
        ca-certificates \
        curl \
        file
ENV REQUIRE_DEPS \
        g++ \
        sudo

RUN set -xe && \
        apt-get update -y && apt-get install -y --no-install-recommends --no-install-suggests \
            ${REQUIRE_DEPS} \
            ${BUILD_DEPS} \
        && rm -r /var/lib/apt/lists/* && \
        curl -sSf https://static.rust-lang.org/rustup.sh | sh && \
        apt-get purge -y \
            ${BUILD_DEPS} \
        && rustc --version
```

> Alpine 雖然安裝過程是正常的，可是執行會有問題，目前尚未知道原因

## Hello World

這裡示範如何輸出 Hello World

先建立檔案 `main.rs`

```rust
fn main() {
    println!("Hello, world!");
}
```

然後下指令編譯

```
rustc main.rs
```

最後就會產生可執行檔，再執行即可

```
$ ./main
Hello, world!
```

## Comment

跟大部分的程式註解方法一樣， Rust 提供這兩種註解表示方法

* `//` 會忽略同一行後面的所有程式碼
* `/* */` 是區塊註解

除此之外，它也有提供文件註解法，需使用 [Rustdoc](https://doc.rust-lang.org/book/documentation.html)。表示方法如下：

* `///`
* `//!`
