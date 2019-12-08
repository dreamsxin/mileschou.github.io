---
title: JSON Web Key
layout: collections
---

[JWK](https://tools.ietf.org/html/rfc7518) 使用 JSON 格式來描述密碼學裡 key 的長相。而密碼學裡提到的演算法即為 [JWA](jwa.md) 所討論的。

而不同的演算法，所定義的格式也稍有不同，可以參考 JWK [section 6](https://tools.ietf.org/html/rfc7518#section-6) 的說明

但共同會有 `kty`，意指 *Key Type*。定義如下：

| kty 值 | Key Type |
| --- | --- |
| oct | Octet sequence（用來表示對稱式加密） |
| RSA | RSA [RFC3447](https://tools.ietf.org/html/rfc3447) |
| EC | Elliptic Curve [DSS](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.186-4.pdf) |

> 有可能會有相同的參數，但不同的演算法，所代表的意義是不同的。

## Octet sequence

這是最單純的表示方法，裡面的只有一個參數：

| 參數 | 用途 |
| --- | --- |
| k | 存放對稱式加密金鑰，需做 `base64url` 編碼 |

對應 [JWA](jwa.md) 所使用的演算法即為 `HS256`、`HS384`、`HS512` 等。

## RSA

## Elliptic Curve
