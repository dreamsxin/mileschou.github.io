---
layout: post
title: JWT 筆記（三）－－JWT 相關資料
tags: [jwt]
---

JWT 相關的 RFC 有很多個，都是由 *JOSE（JSON Object Signing and Encryption）Working Group* 所制定的。

* [JSON Web Signature][]（JWS）
* [JSON Web Encryption][]（JWE）
* [JSON Web Key][]（JWK）
* [JSON Web Algorithms][]（JWA）
* [JSON Web Token][]（JWT）

[JSON Web Signature]: https://tools.ietf.org/html/rfc7515
[JSON Web Encryption]: https://tools.ietf.org/html/rfc7516
[JSON Web Key]: https://tools.ietf.org/html/rfc7517
[JSON Web Algorithms]: https://tools.ietf.org/html/rfc7518
[JSON Web Token]: https://tools.ietf.org/html/rfc7519

JWS 是加上驗證用的簽章，但內容還是明碼的；JWE 會把傳輸的資料加密過。

加密與簽章用的演算法由 JWA 格式記錄，而會用到的 key，則由 JWK 來記錄。

JWK 的屬性基本上都有定義好了，照著文件做就行。

---

JWS 它的組成有三個元素如下：

```
JOSE Header + Payload + Signature

```

*JOSE Header*，其實就是 JWA + JWK + 基本屬性，如：

```json
{
  "typ":"JWT",
  "alg":"HS256"
}
```

接著，有個任務叫 BASE64URL 編碼，它比 base64 編碼多做了一點事：

* `=` 刪光光
* `+` 換成 `-`
* `/` 換成 `_`

然後把下面這個結果，搭配 Header 裡面指定的演算法[做簽章](https://tools.ietf.org/html/rfc7515#section-5.1)

```
ASCII(BASE64URL(UTF8(JWS Protected Header)) || '.' || BASE64URL(JWS Payload))
```

接著就會有 JWS 三個必要元素了：

* JOSE Header
* Payload
* Signature

> 註，當 `alg` 是 `none` 即為不簽章，則 `Signature` 會是空字串（ `.` 結尾）

---

傳輸的方法有兩種，一種是精簡格式 [JWS Compact Serialization](https://tools.ietf.org/html/rfc7515#section-7.1) ，也就是 jwt.io 首頁看到的那樣：

```
BASE64URL(UTF8(JWS Protected Header)) || '.' || BASE64URL(JWS Payload) || '.' || BASE64URL(JWS Signature)
```

另一種則是 [JWS JSON Serialization](https://tools.ietf.org/html/rfc7515#section-7.2)，內容改成 JSON，`General` 版和 `Flattened` 版。General 版資訊會更完整，但就會大很多，另外使用 JSON 原始格式也會有編碼上的問題，所以通常還是 `Compact` 比較通用。

---

最後最複雜的 `JWE` 則是有五個元素：


* JOSE Header
* Encrypted Key
* Initialization Vector
* Ciphertext
* Authentication Tag

Encrypted Key 是一把加密過的 Key，或稱 CEK （*Content Encryption Key*）與 Initialization Vector（IV）都是亂數產生。key 因為要加密，所以通常就會用非對稱式加密，拿收 JWE 的 public key 來加密。也可以加上 x.509 相關資訊確保 public key 的正確性。

Ciphertext 與 Authentication Tag 是加密後的輸出。 `Authentication Tag` 跟簽章很像，是用來確保資料正確性。

最後，一樣它也有 Compact 版跟 JSON 版，下面就 show compact 版的寫法：

```
BASE64URL(UTF8(JWE Protected Header)) || '.' ||
BASE64URL(JWE Encrypted Key) || '.' ||
BASE64URL(JWE Initialization Vector) || '.' ||
BASE64URL(JWE Ciphertext) || '.' ||
BASE64URL(JWE Authentication Tag)
```

---

最後 JWT，就是使用 JWS / JWE 來當做 token。而它另外定義了 payload 裡面屬性，在身分驗證的領域裡，這裡稱之為 *claim*。

用途上，比方說可以把 profile 存在 client 上，對 client 而言，只要確保簽章正確，即可使用 JWT 裡面的資訊。

又或者，把 JWT 當作 token 使用，自然就可以跟 OAuth 結合，如 [RFC 7523](https://tools.ietf.org/html/rfc7523)。

## References

* [JSON Web Token](https://blog.othree.net/log/2016/08/13/json-web-token/) - O3noBlog
