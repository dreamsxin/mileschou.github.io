---
title: Data Types
layout: collections
---

除了 [Built-in Types](built-in-types.md) 外，Elixir 也提供了基於 Built-in Types 建構出來的 Data Type

## String

[String](https://hexdocs.pm/elixir/String.html) 是 UTF-8 編碼過的 binary。從下面這兩個範例可以知道個大概

```
iex> byte_size("世界")
6
iex> String.length("世界")
2
```

## References

* https://hexdocs.pm/elixir/Kernel.html
