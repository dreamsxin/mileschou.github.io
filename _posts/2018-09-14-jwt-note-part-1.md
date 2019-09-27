---
layout: post
title: JWT 筆記（一）－－基本介紹
tags: [jwt]
---

一直很懶得看 [JWT](https://jwt.io/)，直到今天總算該面對了。

官方是這麼描述的：

> JSON Web Token (JWT) is an open standard (RFC 7519) that defines a compact and self-contained way for securely transmitting information between parties as a JSON object.

簡單來說，它是標準，可以參考 [RFC 7519][]。它定義一個可以安全的方法，可以使用 JSON 來交換資訊。

[RFC 7519]: https://tools.ietf.org/html/rfc7519

後面又講了：

> Although JWTs can be encrypted to also provide secrecy between parties, we will focus on signed tokens. Signed tokens can verify the integrity of the claims contained within it, while encrypted tokens hide those claims from other parties. When tokens are signed using public/private key pairs, the signature also certifies that only the party holding the private key is the one that signed it.

雖然它也可以做加密，但它更專注要解決的問題是，簽章（signed）以保證資訊的完整性，尤其在使用公私鑰簽章時，持有公鑰的一方甚至可以確定發行 JWT 的是持有私鑰的一方－－只要拿公鑰驗簽章即可。

什麼場景適合呢？

1. 授權（Authorization），在驗證通過後，即可發行 JWT 來進行使用者後續的資源請求。
2. 資訊交換（Information Exchange），因它可以保證資訊的來源與完整性，所以也很適合作資訊交換。

---

JWT 的結構是一個字串，由兩點 `.` 來分隔出三個區塊，如：

xxx.yyy.zzz

這三個區塊依序如下：

* Header
* Payload
* Signature

三個區塊都是由 JSON + base64encode 的字串所組成。

### Header

Header 通常會由兩個部分組成：

* 類型（typ），通常就叫 `JWT`
* 雜湊演算法（alg），常見的如 `HMAC SHA256` 或 `RSA`

```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

### Payload

Payload 則是存放 claim，代表著實體或使用者相關的資訊。有三種類型：

*   Registered Claims：這是預定義的 claim，可加可不加，但建議要加，如
    | Column | Full name | 中文 |
    | --- | --- | --- |
    | `iss` | Issuer | 發行人 |
    | `sub` | Subject | N/A （對象） |
    | `aud` | Audience | N/A （收件人） |
    | `exp` | Expiration Time | 到期時間 |
    | `nbf` | Not Before | 時間之前（不處理） |
    | `iat` | Issued At | 發行時間 |
    | `jti` | JWT ID | JWT 的唯一識別碼 |
*   Public Claims：在 [IANA JSON Web Token Registry](https://www.iana.org/assignments/jwt/jwt.xhtml) 上註冊的名稱，即是 Public Claims。
*   Private Claims：不屬於上述兩個 Claim，則是 Private Claim。但如果 public claim 有，優先使用 public claims 的命名會比較好。

比方說：

```json
{
  "sub": "1234567890",
  "name": "John Doe",
  "admin": true
}
```

在此例中

* `sub` 是 *Registered Claims*
* `name` 是 *Public Claims*
* `admin` 是 *Private Claims*

### Signature

當有了上述 Header 與 Payload 的資訊後，即可利用 Header 所指定的演算法，與必要的 secret 來為此資訊簽章

收到資訊的一方（也就是上述提到的 `aud`）即可驗證此資訊。
