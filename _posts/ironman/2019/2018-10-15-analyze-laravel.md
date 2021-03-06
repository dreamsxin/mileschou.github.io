---
title: Laravel 原始碼分析
description: 2019 iT 邦幫忙鐵人賽
layout: post
category:
- ironman
tags:
- ironman
- ironman-2019
- laravel
---

Laravel 是目前 PHP 熱門的框架之一；它一定是好用，才會受到大家關注；那對開發者而言，什麼才是好用呢？具備「快速驗證」、「簡潔的程式碼」、「豐富的套件生態系」、「客製化容易」等特性的語言或框架，開發者肯定都會躍躍欲試。未來三十天，筆者將會試著分析 Laravel 原始碼，讓讀者了解什麼是好的架構，並在未來開發設計有好的方向可以參考。

> 此為第十屆 iT 邦幫忙鐵人賽 Software Development 組參選作品之一，同時也獲得鐵人鍊成和[優選](https://ithelp.ithome.com.tw/2019ironman/reward)的成就。

## 前言

其實去年就有想過要寫 Laravel 相關的原始碼分析。在 Laravel 開發過程中，有時會遇到困難或瓶頸，不知如何是好時，這時翻原始碼追原因後，都會有頓悟的感覺。通常是自己耍笨，或是覺得 Laravel 怎麼有這樣的神設計。

因此，會想把這個追原始碼與了解設計的過程筆記起來。在以後設計系統甚至是框架的時候，都能回頭省思現在自己的作品到底是好或不好。

同時，也希望可以幫助更多開發者，無論有沒有用 Laravel，都可以了解什麼是「比較好的」設計，同時也就能避免寫出難以維護的程式碼。不僅自己開心，其他共同維護者也會很開心。

## 目錄

{% assign ironman_articles=site.categories["ironman"] %}

{% include ironman_posts_toc.html articles=ironman_articles topic="analyze-laravel" %}

## 誌謝

* 感謝老婆支持我寫作。
