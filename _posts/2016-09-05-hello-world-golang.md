---
layout: post
title: Hello World Golang
---

雖然對 Go 非常有興趣，可是跟它的語法真的很難適應。今天硬把 Hello world 和 testing 做起來了。

安裝設定 GOPATH 那些就 pass，程式碼如下。

首先要有一個 main package + main function 的檔案，我取名為 `main.go`，這點跟 C 語言應該是一樣的

```go
// main.go
package main

import "fmt"
import "github.com/MilesChou/go-practice/hello"

func main() {
	var s = hello.SayHello()

	fmt.Println(s)
}
```

因為我想做簡單的模組化，所以我把產生 hello world 的方法放到 hello package 裡

```go
// hello/world.go
package hello

func SayHello() string {
	var hello = "Hello World"

	return hello
}
```

接著因為 SayHello 雖然沒有 input 不過可以預期它的 output ，所以可以寫測試，測試要跟待測程式放在一起才有辦法吃到一樣的 namespace

```go
package hello

import (
	"testing"
	"strings"
)

func TestSayHello(t *testing.T) {
	var s = SayHello()

	if !strings.Contains(s, "Hello") {
		t.Error(`No contain "Hello"`)
	}
}
```

查了一下我知道的幾個 go project 它們的測試都是這樣寫，我也不知道對不對，反正就先照做

## Run

直譯執行

    go run main.go

編譯

    go build
    ./project-name

測試，它會自動找所在目錄的測試檔，也可以直接指定 GOPATH 的相對目錄

    cd hello
    go test

## 感想

目前 hello world 做起來還蠻順的，不過它有指標，而且資料結構比較多樣化，所以對我來說應該會比較難入門。

可能 Rust 也會看一下再說
