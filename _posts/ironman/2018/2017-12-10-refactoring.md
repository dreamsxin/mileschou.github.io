---
title: 看到 code 寫成這樣我也是醉了，不如試試重構？
description: 2018 iT 邦幫忙鐵人賽
layout: post
category:
- ironman
tags:
- ironman
- ironman-2018
- refactoring
---

有過慘痛維護經驗的開發者都會了解，程式是需要設計的！設計不良的架構，會在未來增修功能的時候，大喊要殺了某人；但追求完美設計的下場，反而會被不懂程式的非工程人員追進度，還會被嫌沒效率；「重構」能在這兩個極端之間取得一個平衡。它能在具備基本設計的架構上，持續以增修功能為目的，補足設計上的缺陷。不僅能持續交付程式碼，也能持續改善設計，好重構，不試嗎？

## 前言

雖然我看過的程式不是很多，但犯過的蠢事相信絕對不少，至少有寫過無數難以維護的程式碼。而當我在新增功能不順利的時候，最想殺的那個人，通常都是數個月前的自己。

為了不讓未來的自己起殺意，於是開始學設計模式、重構、單元測試、[持續整合][]、DevOps …等。學習與分享不為別的，除了求其他人（包括未來的自己）不要殺我之外，也真心希望大家能帶著愉快的心情，開發出真正有價值的軟體。

現在，雖然骯髒的程式碼已經寫下去了，但軟體是軟的，還回得去。重構正是其中一個有用的技巧，可以讓原本的殺意降低，愉快的心情增加。除此之外，還能提高程式碼的穩定度，讓大家對程式碼更有信心，也對部署更放心。

未來 30 天，將會分享我對於重構的了解，以及示範如何做重構，希望大家對重構能有更深刻的認識。

[持續整合]: {% post_url ironman/2017/2016-11-30-start-to-ci %}

## 目錄

{% assign ironman_articles=site.categories["ironman"] %}

{% include ironman_posts_toc.html articles=ironman_articles topic="refactoring" %}

## 誌謝

* 感謝老婆為了支持我寫作，把家裡打點好好的，也感謝老婆幫我看文章。
* 互相鼓（ㄕㄤ）勵（ㄏㄞˋ）的團隊成員 [聖佑](https://github.com/shengyou) 與 [Scott](https://github.com/shazi7804)
* 幫忙看文章的 [@pexlkw](https://github.com/pexlkw) 與 [@phoebe90](https://github.com/phoebe90)
* 互相推坑的 [DevOps Taiwan](https://www.facebook.com/groups/DevOpsTaiwan/) 夥伴們
