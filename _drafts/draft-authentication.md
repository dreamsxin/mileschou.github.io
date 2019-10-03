# SAML / OpenID

## 參考資料

* [【臺北市政府教育局】用 Laravel 打造單一身分驗證服務](https://medium.com/laraveldojo/the-story-behind-tp-edu-with-laravel-47fe68a51d8a)

# OAuth 2.0 Authorization Framework

## 什麼是授權？

身分驗證（Authentication）、授權（Authorization）與 ACL（Access Control List）或 RBAC（Role-based Access Control）的差異

### 身分驗證

透過身分驗證，可以讓系統知道目前的使用者是誰。

如：輸入 root 帳號密碼成功，可以知道現在進來的使用者，是 Linux 裡所定義的超級使用者（super user）。

### 授權

只有資源擁有者（resource owner），才具有授權的權利。而授權的目的是，讓非資源擁有者，取得資源擁有者的資源。

如：使用者的大頭照資源放在 Facebook，而某第三方軟體如 Mediem，想在登入過程想取得使用者的大頭照，必須要經過使用者的授權。而要或不要，決定權在於使用者。

### 存取控制

系統管理者，或被授權的使用者，才有權利更改存取控制的策略。目的是，管理並控制使用者存取資源的權限。

如：留言板系統，前台使用者只能留言，後台使用者可以刪除留言。與授權最大不同在於，擁有資源的使用者，不一定會有資源管理的決定權。

## 參考資料

* [ory/keto](https://github.com/ory/keto)
* [RFC 6749 - The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)
* [Oauth Status Pages](https://tools.ietf.org/wg/oauth/)
* [從簡單到繁複的OAuth2](https://www.ithome.com.tw/voice/129385) - 林信良
* [一次搞懂OAuth與SSO在幹什麼?](https://studyhost.blogspot.com/2017/01/oauthsso.html)

# Introspection / Revocation

# OAuth 2.0 for Native Apps

## 參考資料

* [OAuth 2.0 for Native Apps](https://tools.ietf.org/html/rfc8252)
* [Securely set up OAuth2 for Mobile Apps, Browser Apps, and Single Page Apps](https://www.ory.sh/oauth2-for-mobile-app-spa-browser/)

# JSON Web Token

## 參考資料

* [JSON Web Token (JWT)](https://tools.ietf.org/html/rfc7519)
* [JSON Web Token (JWT) Profile for OAuth 2.0 Access Tokens](https://tools.ietf.org/html/draft-ietf-oauth-access-token-jwt-01)
* [JSON Web Token Best Current Practices](https://tools.ietf.org/html/draft-ietf-oauth-jwt-bcp-06#section-3.5)
* [JSON Web Token(JWT) 簡單介紹 - Leon's Blogging](https://mgleon08.github.io/blog/2018/07/16/jwt/)
* [fernet/spec](https://github.com/fernet/spec)
* [PASETO](https://paseto.io/)

# Assertion Framework

## 參考資料

[RFC 7521 - Assertion Framework for OAuth 2.0 Client Authentication and Authorization Grants](https://tools.ietf.org/html/rfc7521)
[RFC 7522 - Security Assertion Markup Language (SAML) 2.0 Profile for OAuth 2.0 Client Authentication and Authorization Grants](https://tools.ietf.org/html/rfc7522)
[RFC 7523 - JSON Web Token (JWT) Profile for OAuth 2.0 Client Authentication and Authorization Grants](https://tools.ietf.org/html/rfc7523)

# OpenID Connect

# Multi-factor authentication

# Security issue - Token Revocation

# OAuth 2.0 Security Topic

* [RFC 6819 - OAuth 2.0 Threat Model and Security Considerations](https://tools.ietf.org/html/rfc6819)
* [draft-ietf-oauth-security-topics-13 - OAuth 2.0 Security Best Current Practice](https://tools.ietf.org/html/draft-ietf-oauth-security-topics-13)

# User impersonation

## 參考資料

* [User impersonation](https://support.google.com/admanager/answer/1241070?hl=en)
