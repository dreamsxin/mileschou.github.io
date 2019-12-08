---
title: JWT
layout: collections
---

官方的描述如下：

> JSON Web Token (JWT) is an open standard (RFC 7519) that defines a compact and self-contained way for securely transmitting information between parties as a JSON object.

簡單來說，它是個標準，可以參考 [RFC 7519][JSON Web Token]。它定義一個安全地使用 JSON 來交換資訊的方法。後面又提到：

> Although JWTs can be encrypted to also provide secrecy between parties, we will focus on signed tokens. Signed tokens can verify the integrity of the claims contained within it, while encrypted tokens hide those claims from other parties. When tokens are signed using public/private key pairs, the signature also certifies that only the party holding the private key is the one that signed it.

雖然它也可以做加密，但它更專注要解決的問題是，簽章（signed）以保證資料完整性（data integrity），尤其在使用公私鑰簽章時，持有公鑰的一方甚至可以確定發行 JWT 的是持有私鑰的一方－－只要拿公鑰驗證簽章即可。

什麼場境適合呢？

1. 授權（authorization），在驗證通過後，即可發行 JWT 來進行使用者後續的資源請求。
2. 資訊交換（information Exchange），因它可以保證資訊的來源與完整性，所以也很適合作資訊交換。

主要的 RFC 有下列五個，都是由 *JOSE(JSON Object Signing and Encryption) Working Group* 所制定的：

* [JSON Web Signature][] (JWS)
* [JSON Web Encryption][] (JWE)
* [JSON Web Key][] (JWK)
* [JSON Web Algorithms][] (JWA)
* [JSON Web Token][] (JWT)

> 還有其他延伸應用的 RFC，但主要的定義是上面這五個

*JWS* 是加上驗證用的簽章，但內容還是明碼的；*JWE* 會把傳輸的資料加密過。加密與簽章用的演算法由 *JWA* 格式記錄，而會用到的 key 則由 *JWK* 來記錄。*JWT* 則是結合以上的規範，定義出 token 的長相。

[JSON Web Signature]: https://tools.ietf.org/html/rfc7515
[JSON Web Encryption]: https://tools.ietf.org/html/rfc7516
[JSON Web Key]: https://tools.ietf.org/html/rfc7517
[JSON Web Algorithms]: https://tools.ietf.org/html/rfc7518
[JSON Web Token]: https://tools.ietf.org/html/rfc7519
