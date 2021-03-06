---
layout: post
title: 我所知道的 DevOps
---

昨天，一位朋友問我說：「怎樣才算懂 CI/CD？」 ；另一位朋友則是問：「DevOps 要怎麼去了解？」。

在這一瞬間，我突然有點遲疑。

約在一年前，一位 Java 資深前輩跟我說了參加 DevOps 2015 之後的心得，也聊了 DevOps 的一些重點。當時正覺得 Vagrant 建置的有點沒方向，卡在 Developer & Operator 之間。此時 DevOps 字面上強調的重點，剛好解了我的疑惑。於是我決定未來一定要去深入研究 DevOps 。後來參加 DevOpsTaiwan Summit 2016 後，也了解了大神們是如何看 DevOps 的。

回顧這一年中，確實學了不少東西，只是這些經驗都是由其他人傳承下來的。我自認不聰明，但對 DevOps 很有興趣，所以會用力去體會它。今天要我去把這些想法好好地傳達給其他人，還是會擔心不精準。不過相信打了這篇文章同時好好思考過之後，下次會更好。

---

> 「怎樣才算懂 CI/CD ？」

我個人是覺得要先懂一些基本概念後，才能開始從實務上去體會一些問題。

*Continuous Integration* 持續整合，也有人翻譯成頻繁整合。所以首先應該要做的事是：觀察目前整合的狀況，通常觀察的結果都會想修正一些問題。覺得有問題是好事，這樣才能做到持續改善。最常看到，同時也最表面的問題，就是整合時間太久，所以大部分團隊第一個考慮的解決方案都是自動化。

常聽到有人說要導入 CI 就會跟自動化測試畫上等號。當然這沒問題，只是要記得一件事：**「CI 精神跟自動化測試並沒有直接關係」**

CI 文字上的意思，是叫大家要隨時整合。團隊也可以選擇人工整合，每一個 commit 都人工整合一次，這樣也有達到 CI 的精神呀！只是因為人工整合成本太高，時間也比較久，所以大部分都會改成自動化。

了解 CI 精神跟自動化測試並沒有直接關係後，那是不是有不做自動化也能達到 CI 精神？有的，舉個例子：假設整合常常失敗，那減少重新整合的次數，也是一個可行方向，比方說每次 commit 程式碼少一點－－因為 commit 的程式碼越少，就越能預測它的結果。其他 CI 還要考慮到如何建置整合測試的環境；產生一些測試報表供相關人員參考等，這些都是跟整合相關的例子，當然還有很多很多。只是為了要達到「頻繁」，大家討論的通常都是自動化工具居多。

上述是想導入 CI 精神的過程和一點想法。當有成功導入 CI 精神後，開發者可以快速得到提交程式碼的品質，品質不好可以立刻抓到問題並修正；品質好會對自己的程式更有信心，這些都是導入 CI 帶來的表面和潛在好處。

---

CD 有兩種解釋，一種是 *Continuous Delivery*，另一種是 *Continuous Deployment*，Delivery 我個人定義是把產品交付給直接管理產品的角色，如經理；Deployment 則是交付給 End User。我的定義上只是交付對象不同，不過精神上是差不多的－－把完成的產品快速交給想看的人。以下會以交付 End User 當作目標。

CD 字面上的精神雖然跟 CI 看起來有一半不一樣（差一個單字），但我覺得它比較像是 CI 延伸的概念。假設 CI 可以把關品質的話，那沒有 CI 的 CD，只是在快速交付 Bug。而回頭來看 CI，它也有交付的對象－－交付整合結果給開發者。再進一步想想，CI 達成了快速交付的好處是什麼，不就是回饋開發者 Commit 結果嗎？CD 最大的好處也是一樣，如果能快速地提供 End User 功能，他們也會快速地給 Manager 一些回饋，進而讓產品更加完整。

CD 跟 CI 最大不同點，在於要考慮的執行環境：CI 通常是沙箱環境中執行，而 CD 會是營運環境中執行，因此要考慮到即有系統的可用性與完整性，比方說：資料備份、資料遷移、停機時間盡可能縮短等，Anyway，為了「頻繁」想做什麼樣的改善都可以。

記住 CI/CD 並不是工具，而是精神。對我來說，能覺得能體會上述內容，就是懂 CI/CD 了。
