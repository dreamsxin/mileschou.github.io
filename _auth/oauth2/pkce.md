---
title: Proof Key for Code Exchange
layout: collections
---

參考 [OAuth 2.0 說明](https://oauth.net/2/pkce/)

## Terminology

* code verifier - 一個用來讓 authorization request 與 token request 產生關聯的隨機加密字串
* code challenge - 從 code verifier 產生的 challenge，會夾帶到 authorization request 一起送出，以便後續驗證
* code challenge method - code challenge 的方法


## Protocol

### Client 產生 Code Verifier

### Client 產生 Code Challenge

格式如下：

plain
  code_challenge = code_verifier

S256
  code_challenge = BASE64URL-ENCODE(SHA256(ASCII(code_verifier)))

> 如果可以用 S256 就用，因技術原因且從設定知道服務支援 plain 時，才能使用 plain。

### Client 送出帶有 Code Challenge 的 Authz Request

帶的參數如下：

code_challenge - 必要
code_challenge_method - 選用，預設是 plain，可以用 S256 或 plain

### Server 回傳 Code

在 Server 產生 authorization code 時，同時要把 authorization code 跟 `code_challenge` 與 `code_challenge_method` 建立關聯（因為後面要拿來做驗證）

關聯的方法如，把這兩個值加密藏在 authorization code 裡；或是直接存在 server；但不能讓任何人取得 `code_challenge` 的內容

> 如何關聯，不在本 spec 討論範圍裡

若 server 要求 public client 提供 PKCE，但 client 沒提供 `code_challenge`，server 必須回傳 authorization error response，error 為 `invalid_request`、`error_description` 應該說明發生什麼事，如：`code challenge required.`。

### Client 取得 Token

當依 OAuth 2.0 Access Token Request 規範取 Access Token 時，除了 Authorization Code 及原有參數外之外，還必須要帶 Code Verifier：

* code_verifier

`code_challenge_method` 因為在發行 code 的時候已經有綁定了，因此這時必須依照綁定的方法來做驗證。

### Server 驗證 code_verifier

### 兼容性

## 實作

| 語言 | 套件 |
| --- | --- |
| PHP | [thephpleague/oauth2-server 5.1.0+](https://github.com/thephpleague/oauth2-server/tree/5.1.0) |
