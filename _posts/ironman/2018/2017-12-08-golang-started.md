---
title: 從無到有，使用 Go 開發應用程式
description: 2018 iT 邦幫忙鐵人賽
tags:
- golang
---

Go 是最近流行的語言之一，許多知名的工具或服務都使用 Go 開發，如 Docker、Drone CI 等。未來 30 天，我將會從安裝 Go 的開發環境開始、到寫應用程式、最後部署 API Server 的過程，完整筆記下來。除了逼迫自己學習外，也希望能讓有緣的朋友也可以順利入門一探 Go 的奧妙。

## 前言

我熟悉 PHP，也了解 PHP 效能上的瓶頸。曾經想過該如何優化效能，從改演算法，到參考各文章的建議效能優先寫法，還是無法突破。曾考慮過 [Phalcon](https://phalconphp.com)，也做了 [Docker Image](https://hub.docker.com/r/mileschou/phalcon)，但因轉換時間成本過高，加上數據不足無法證明比較快，最後還是沒有應用在工作上。

正因如此，才會想學習比較高效能的語言。心中打的算盤是：把複雜運算交由高效能語言處理，Web 則交由 PHP 負責。

語言選擇除了 Go 之外，也曾看過 Node、Rust、Python 等，但最後我選擇了 Go。除了它有著老爸撐腰，加上使用過許多好用的工具（如 Docker）也是用 Go 撰寫的，因此對 Go 的很有信心。

之前也曾經寫過 Hello World 就沒再繼續下去，覺得這樣不行。這次希望自己在這 30 天之中，能成功地寫出一個像樣的東西。

## 目錄

{% assign ironman_articles=site.categories["ironman"] %}

{% include ironman_posts_toc.html articles=ironman_articles topic="golang-started" %}

## 誌謝

* 良葛格無私貢獻詳細的[學習筆記](https://openhome.cc/Gossip/Go/index.html)。
