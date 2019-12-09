---
title: Print
description: Rust 學習筆記
layout: collections
---

`std::fmt` 裡有幾個 print 相關方法

* `format!` 格式化字串，並回傳格式化後的字串
* `print!` 同上，差在字會印到 console
* `println!` 同上，差在會額外加 new line

> 跟 printf 很像

### Basic

```rust
fn main() {
    println!("{} {} ago", 31, "days");
}
```

`{}` 是 placeholder ，後面的 31 和 days 會依續填進 `{}` 裡。又因為 println! 巨集會輸出並換行，所以結果如下

```
$ ./print
31 days ago
```

也可以像這樣用

```rust
fn main() {
    println!("{0}不{1}，{1}不{0}", "開車", "喝酒");
}
```

或是命名

```rust
fn main() {
    println!("{something} is like {another}", "My phone", "iPhone");
}
```

## References

* http://rustbyexample.com/hello/print.html
