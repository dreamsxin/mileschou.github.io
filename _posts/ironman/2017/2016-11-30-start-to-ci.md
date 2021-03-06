---
title: CI 從入門到入坑
description: 2017 iT 邦幫忙鐵人賽
layout: post
category:
- ironman
tags:
- ironman
- ironman-2017
- continuous-integration
---

DevOps 說：開發、測試與維運應該互相合作，解決問題並完成任務。CI 的目標是：開發與測試密切合作，並產出讓維運可快速部署的高品質軟體。對開發者來說 CI 也是個快速回饋機制，相信沒有什麼能比「寫完程式立即看到成果」來的興奮的事了。就讓我們來體驗 30 天的興奮，並一起入坑吧！

這 30 天裡，我將會以開發者角度，並以第一人稱來說明 CI 是個什麼樣的概念，以及它幫助了我什麼，又幫助團隊什麼。

> 此為第八屆 iT 邦幫忙鐵人賽 DevOps 組參選作品之一，同時也獲得鐵人鍊成和[優選](https://ithelp.ithome.com.tw/2017ironman/8th_winner)的成就。

* [CI 從入門到入坑](http://ithelp.ithome.com.tw/users/20102562/ironman/987)
* [GitBook](https://www.gitbook.com/book/mileschou/intro-of-ci/details)
* [GitHub](https://github.com/MilesChou/book-intro-of-ci) 

如對文章有任何建議，歡迎隨時提 issue 或直接發 PR。修改的規範可以參考 [CONTRIBUTING](/CONTRIBUTING.md) 文件。

## 前言

在開始寫作之前，我想先聊一下，為何我會選 CI 當作是主題吧！

至今跟許多人聊 CI，有些人以為它是特效藥。好一點的還知道要請測試人員寫腳本，讓電腦代替人工自動化處理測試步驟，再手動觸發 CI server 處理；慘一點的，搞不好覺得請 MIS 架 CI server 串專案後，bug 就會煙消雲散。

**假的！**

CI 是一個觀念或文化，大部分的人講 CI 都是在說 CI server，雖然有相關，但是它們有點不大一樣。一定是先有 CI，才會有 CI server。但上述這些人很有可能都忘了 CI 最初的原意了。

[Waterfall][] 裡，開發階段和測試階段被明顯區分開來。也許這做法有某些優點，但在現今講究快速迭代開發的時代裡，它的缺點特別明顯。對於在意這些缺點的 Waterfall 團隊而言，CI 是特效藥沒錯，而且是個非常苦，讓人嚥不下口的良藥。如同簡介所說，CI 講的正是「開發與測試密切合作」。習慣 Waterfall 的朋友，通常比較難理解這些好處。只有在藥效出現作用時，才會知道它真的能解決專案的某些問題。

選 CI 當主題是因為，我想在藥外面包一層糖衣，雖然說穿了還是在吃藥，但至少讓這些朋友們比較願意服用。服用完後，軟體品質不一定能馬上提高，但相信至少不會再爛下去了，接著維運部署高品質軟體上線自然會更安心，也更有信心！

最後，祝大家都能 **快快樂樂開發，平平安安上線。**

## 目錄

{% assign ironman_articles=site.categories["ironman"] %}

{% include ironman_posts_toc.html articles=ironman_articles topic="start-to-ci" %}

## 誌謝

* 推坑的 [DevOps Taiwan](https://www.facebook.com/groups/DevOpsTaiwan/) 好友們
* 一起鐵腿的同伴 @chusiang，作品：[現代 IT 人一定要知道的 Ansible 自動化組態技巧](https://github.com/chusiang/automate-with-ansible)
* 抽空看文章並提供意見的 @theqwan-chengwei

[Waterfall]: https://en.wikipedia.org/wiki/Waterfall_model
