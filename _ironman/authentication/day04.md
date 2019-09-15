---
title: 基礎協定
---

在第一天 [定義範圍](day01.md) 有提到，此系列文將會專注在 web 上，因此我們必須得了解 web 的基本協定 HTTP 特色為何，以及我們該如何在這協定基礎上做身分驗證。

## HTTP

HTTP 的全名為 *Hypertext Transfer Protocol*，在 [OSI 模型](https://en.wikipedia.org/wiki/OSI_model)裡，它屬於應用層的協定，可以透過 TCP 或 TLS 來發送或接收資訊。

參考 [MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Evolution_of_HTTP) 講 HTTP 的歷史，有分下列幾個版本：

* HTTP/0.9，1991 年發佈，一行指令就能發送請求，但只能使用 GET，以及格式只能回傳 HTML
* HTTP/1.0，1996 年發佈，但其實在這之前，各家瀏覽器與服務器都是各自做自己的，並沒有任何共識。這時發佈的 1.0 就有點像是參考各家的實作，來重新定義 HTTP 如何操作
* HTTP/1.1，1997 年發佈，這個版本是目前廣泛使用的協定，它在定義上保留了許多擴展空間（如 Header），讓建構在 HTTP/1.1 上的應用程式或其他基於 HTTP 的協定，更有發揮的空間
* HTTP/2.0，2015 年發佈

## 參考資料

* [Evolution of HTTP](https://medium.com/platform-engineer/evolution-of-http-69cfe6531ba0)
* [The Original HTTP as defined in 1991](https://www.w3.org/Protocols/HTTP/AsImplemented.html)
* [RFC 1945 - Hypertext Transfer Protocol -- HTTP/1.0](https://tools.ietf.org/html/rfc1945)
* [RFC 2068 - Hypertext Transfer Protocol -- HTTP/1.1](https://tools.ietf.org/html/rfc2068)
* [RFC 2616 - Hypertext Transfer Protocol -- HTTP/1.1](https://tools.ietf.org/html/rfc2616)
* [RFC 6265 - HTTP State Management Mechanism](https://tools.ietf.org/html/rfc6265)
* [RFC 6455 - The WebSocket Protocol](https://tools.ietf.org/html/rfc6455)
* [RFC 7540 - Hypertext Transfer Protocol Version 2 (HTTP/2)](https://tools.ietf.org/html/rfc7540)
* [W3C Recommendation - Server-Sent Events](https://www.w3.org/TR/eventsource/)