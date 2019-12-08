---
title: 授權給原生應用程式
layout: collections
---

OAuth2 主要是設計在 web 環境上的，所以裡面定義的規範大多都跟 web 相關協定有關，如 [HTTP][RFC 2616]。

但原生應用程式則是另一種應用情境，即使有嵌入式瀏覽器可以使用，但一來安全性低，實作複雜度也會提高，是一個百害無一利的選擇。 

[RFC 8252][] 是針對這個問題，來更新 [OAuth 2.0][RFC 6749] 的規範。以下試著翻譯原文。

## 摘要

從原生應用程式來的 OAuth 2.0 授權請求應該只能經由外部的使用者代理，主要是使用者的瀏覽器。此規範詳細說明為何要這樣做的安全性與可用性原因，以及原生應用程式與授權伺服器如何實現最佳實踐。

## 備忘錄的狀態

此備忘錄記錄了 Internet 的最佳實踐（Best Current Practice，簡稱 BCP）

## 1. 簡介

[OAuth 2.0 第九節](https://tools.ietf.org/html/rfc8252#section-9)記錄了兩種原生應用程式跟授權接口互動的方法：使用嵌入式的 user-agent，或是外部的 user-agent。

此最佳實踐要求在原生應用程式使用 OAuth 時，只能使用外部的 user-agent，如瀏覽器。也記錄了原生應用程式如何使用瀏覽器，做為預設的外部 user-agent 來實現授權流程，以及授權伺服器如何支援這類的需求。

這個做法也被稱為「AppAuth pattern」，可以參考實現它的 open-source [AppAuth][]

[AppAuth]: https://appauth.io/
[RFC 2616]: https://tools.ietf.org/html/rfc2616
[RFC 6749]: https://tools.ietf.org/html/rfc6749
[RFC 8252]: https://tools.ietf.org/html/rfc8252

## 2. 用詞規定

## 3. 術語

原生應用程式（native app)：裝在使用者裝置上的應用程式，不同於需要瀏覽器執行的 web 應用程式（web app）。使用基於 web 技術開發但作為原生應用程式發佈的應用程式，即混合應用程式（hybrid app），也視同於本規範所稱的原生應用程式。
