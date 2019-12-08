---
title: Authorization Code Flow
layout: collections
---

流程描述如下：

1.  Client 準備帶有必要參數的驗證請求（Authentication Request）
2.  Client 將驗證請求發送給 Authorization Server
3.  Authorization Server 驗證 End-User 身份
4.  Authorization Server 取得 End-User 授權
5.  Authorization Server 將授權碼（Authorization Code）透過 End-User 送回給 Client
6.  Client 使用授權碼向 Authorization Server 的 token endpoint 發送請求
7.  Client 收到代表 End-User 身份的 ID Token 跟 Access Token
8.  Client 驗證 ID Token 並取出使用者資訊

## Authentication Request

[Authentication Request](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest) 是請求 Authorization Server 對 End-User 做身分驗證的 [OAuth 2.0 Authorization Request](https://tools.ietf.org/html/rfc6749#section-4.1.1)。

Authorization Server 需支援 [RFC 2616](https://tools.ietf.org/html/rfc2616) 所定義的 `GET` 與 `POST` 方法。Client 可以使用 `GET` 或 `POST`，把 Authentication Request 發送給 Authorization Server。如果是 `GET`，使用 [Query String Serialization](serializations.md#query-string-serialization) 序列化參數；如果是 `POST`，則使用 [Form Serialization](serializations.md#form-serialization) 序列化參數。

Authorization Code Flow 依循 OAuth 2.0 的請求參數：

| 參數 | 必要/ | 說明 |
| --- | --- | --- |
| `scope` | **REQUIRED** | OpenID Connect **必須**要有 `openid` 的 scope。如果沒有 `openid` 的話，就不執行身分驗證行為，但**可以**同時存在其他 scope |
| `response_type` | **REQUIRED** | 返回有多種類型，Authorization Code Flow 使用 `code` |
| `client_id` | **REQUIRED** | Authorization Server 上合法且可識別的 OAuth 2.0 Client  |
| `redirect_uri` | **REQUIRED** | 要把 response 轉導到哪個 URI，它**必須**與預先註冊的 Redirection URI 之一完全一致，使用此流程時，此值**應該**使用 HTTPS |
| `state` | *RECOMMENDED* | 用在確認 request 與 callback 是同步一致的，把這個值與瀏覽器的 cookie 綁定，可以阻擋 CSRF 攻擊 |
