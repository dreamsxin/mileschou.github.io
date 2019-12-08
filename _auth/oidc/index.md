---
title: OpenID Connect
layout: collections
---

OpenID Connect 通常簡稱 *OIDC*。它有幾份[規格](https://openid.net/developers/specs/)（specifications）需要先讀如下：

| 全名 | 用途 |
| --- | --- |
| [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html) | 定義 OIDC 的核心功能 |
| [OpenID Connect Discovery](https://openid.net/specs/openid-connect-discovery-1_0.html) | 定義 Client 如何動態的發現 OP 的資訊 |
| [OpenID Connect Dynamic Registration](https://openid.net/specs/openid-connect-registration-1_0.html) | 定義 Client 如何動態跟 OP 註冊 |
| [OAuth 2.0 Multiple Response Types](https://openid.net/specs/oauth-v2-multiple-response-types-1_0.html) | 為 OAuth2 定義幾個新的 response types |
| [OAuth 2.0 Form Post Response Mode](https://openid.net/specs/oauth-v2-form-post-response-mode-1_0.html) | 定義如何使用 HTTP Post 自動提交 HTML Form，並拿到 OAuth2 授權的 response parameters |
| [OpenID 2.0 to OpenID Connect Migration 1.0](https://openid.net/specs/openid-connect-migration-1_0.html) | 如何從 OpenID 2.0 遷移成 OpenID Connect |

## 身分驗證

OpenID Connect 會執行身分驗證以讓使用者登入，或是確認使用者是否已登入。它會以安全的方法把身分驗證的結果傳給 Client，而 Client 因為會依賴 OpenID Connect 的驗證結果，所以稱之為 Relying Party（RP）。

驗證結果會以 *ID Token* 的形式傳給 Client，裡面的內容可以參考定義。

而身分驗證有三種流程可以選擇：

* [Authorization Code Flow](authorization-cdoe-flow.md)
* [Implicit Flow](implicit-flow.md)
* [Hybrid Flow](hybrid-flow.md)

不同的流程會使用不同的方法把 ID Token 與 Token 傳給 Client。

三個流程的特徵如下表：

| Property | Authorization Code Flow | Implicit Flow | Hybrid Flow |
| --- | --- | --- | --- |
| Authorization Endpoint 可以回傳所有 Token？ | no | yes | no |
| Token Endpoint 可以回傳所有 Token？ | yes | no | no |
| Tokens not revealed to User Agent | yes | no | no |
| Client can be authenticated | yes | no | yes |
| Refresh Token possible | yes | no | yes |
| Communication in one round trip | no | yes | no |
| Most communication server-to-server | yes | no | varies |

不同的流程，Authorization Request 的 `response_type` 就會有所不同。`response_type` 與流程的對應如下表：

| "response_type" | Flow |
| --- | --- |
| code | Authorization Code Flow |
| id_token | Implicit Flow |
| id_token token | Implicit Flow |
| code id_token | Hybrid Flow |
| code token | Hybrid Flow |
| code id_token token | Hybrid Flow |

[參數序列化（Serializations）](serializations.md)

## References

* https://medium.com/@darutk/diagrams-of-all-the-openid-connect-flows-6968e3990660
