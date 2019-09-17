---
layout: post
title: 我是誰？我在哪？
description: iT 邦幫忙第十一屆鐵人賽
category:
- ironman
tags:
- ironman
- ironman-2020
- authentication
---

最終決定參賽了，選了我目前的主要工作－－身分驗證做為主題。

雖然說是主要工作，實際上只不過是比其他開發者多碰了一點皮毛，因此未來三十篇文章，還有很多事前的努力需要做，加上手邊有專案正在進行，還有兩場演講都還沒有頭緒。雖然辛苦，但未來也許就更沒空寫文章了，還是想把握最後的機會來達成不可能的成就！

雖然是這麼說，去年寫 [Laravel 原始碼分析]({% link _ironman/analyze-laravel.md %})的時候，平均每天都一點才睡，真的很累。這次如果覺得不行的話，就會直接斷賽了。

---

大多數的系統，為了區分使用者權限，都會存在著身分與角色功能，像是如同超人一般的 root，抑或是毫無存在感的 guest。系統的身分驗證功能，是非常需要注重安全的，不然人人都是 root 豈不天下大亂？未來三十天將會跟大家討論，在網頁架構下如何安全地做身分驗證。

## 目錄

{% assign ironman_articles=site.categories["ironman"] %}

{% include ironman_posts_toc.html articles=ironman_articles topic="authentication" %}

## 備存

* https://medium.com/@jaydenlin/c3b45d3bbc32

## 誌謝

* 感謝老婆為了支持我寫作，將家裡打點好好的
