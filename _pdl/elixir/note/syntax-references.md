---
title: Syntax References
layout: collections
---

## 特色

在 Elixir 世界裡，函式的稱呼方法有點不大一樣，比方說有個函式叫 `String.length`，並定義有一個參數，則會稱此函數為：

```
String.length/1
```

而 Elixir 裡幾乎都是函式，包括運算子也是：

```
iex(1)> fun = &!/1 
#Function<6.128620087/1 in :erl_eval.expr/5>
iex(2)> Function.info(fun)
[
  ...
]
```

## References

* [Syntax References](https://hexdocs.pm/elixir/syntax-reference.html)
