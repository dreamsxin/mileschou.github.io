---
title: Pattern Matching
layout: collections
---

[Pattern Matching](https://elixir-lang.org/getting-started/pattern-matching.html) 可以比對值、結構甚至是函數。

在 Elixir 裡， `=` 不單純是 *賦值運算* ，而同時會做 *比對運算*。比對運算就類似同以前學習方程式一樣，要解出 x 是多少。當比對成功會回傳此等式的結果。同時若左邊有變數的話，會同時做賦值：

```
iex> x = 1
1
```

這時 x 就會是 1，若反過來寫，等式也是成立的：

```
iex> 1 = x
1
```

但把它改成 2 = x 就會錯誤了

```
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

改成 2 = x * 2 也會成立

```
iex> 2 = x * 2
2
```

因為可以用在複雜結構或是運算上，所以就會有一般比較特別的例子：

```
iex> "foo" <> x = "foobar"
"foobar"
iex> x
"bar"
```

或是 list

```
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [1, x, y] = list
[1, 2, 3]
iex> x
2
iex> y
3
```

因為 list 可以這樣玩，所以也可以做到 swap

```
iex> a = 1                
1
iex> b = 2
2
iex> [a, b] = [b, a]
[2, 1]
iex> a
2
iex> b
1
```

## pin operator

一開始有提到，若左邊有變數的話，將會做賦值運算。但有時候我們不期望這樣，這時就可以使用 pin `^`：

```
iex> x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
```

再看下面這個例子或許就更能了解：

```
iex> x = 1           
1
iex> {x, ^x} = {2, 1}
{2, 1}
iex> {x, ^x} = {2, 1}
** (MatchError) no match of right hand side value: {2, 1}
```

其中第二行 `{x, ^x} = {2, 1}` 裡，`x` 是會被賦值的，所以會運算再塞人。`^x` 因為不會被賦值，所以會保持是 1，因此比對成立的。

第三行因為 x 已變成是 2，所以 `^x` 就會固定是 2，因此比對無法成立。

> 某種程度而言，這個特性就有點類似其他語言常見的常數（constant），但 Elixir 的設計與應用比較特別一點。
