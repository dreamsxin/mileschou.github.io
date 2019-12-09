---
title: 內建型態與用法
layout: collections
---

在 Python 的世界裡面，萬物皆物件。但還是可以用實字表示一些基本型態。

## 數值型態

Python 3 跟數值相關的型態有

* 整數 `int`
* 複數 `complex`
* 浮點數 `float`
* 布林 `bool`

### 整數

各種進位的實字表示法

```python
number = 10      # 10
number = 0b1010  # 10
number = 0o12    # 10
number = 0xa     # 10
```

其他格式轉換為 int 的方法

```python
number = int('10')    # 10, string to int
number = int(10.0)    # 10, float to int
number = int(True)    # 1, bool to int
```

如果是字串轉 int 的話，可以改基底。基底範圍為 `>= 2 and <= 36` ，也就是最大可以使用 數字 0 ~ 9 + a ~ z ，共 36 進位，英文不區分大小寫。

```python
number = int('10', 10)   # 10, default
number = int('10', 8)    # 8
number = int('10', 16)   # 16
number = int('10', 2)    # 2
number = int('1z', 36)   # 71 (36 + 35)
```

### 複數

實字表示法

```python
complex1 = 2 + 3j
complex2 = 4 + 5j
complex3 = complex1 + complex3    #  6 + 8j
```
