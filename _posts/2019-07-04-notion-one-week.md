---
title: Notion 把玩一週心得
layout: post
tags:
- notion
---

繼上個禮拜 [Notion 初體驗]({% post_url 2019-06-29-notion-started %})至今玩快一個禮拜，也漸漸更清楚它的缺點了。

1. 有免費的試用空間，但重度使用則必須付費
2. Database 裡面的頁面不會出現在樹狀結構裡
3. Database 沒有 1 to 1 的對應功能

## Notion 的付費模式

不可能完全免費，這是可以理解的，畢竟服務要能維持下去的前提就是需要錢。若得付費的話，就得先了解它的付費模式，才知道最佳的付費時間為何。

如 [Sorted³](https://staysorted.com/) 可以無限試用兩個禮拜，因此最後決定付費的時間是無法變動的。

[Notion 方案選擇](https://www.notion.so/11148f631d5b4071af9ffb0063d0ef63)

從上表可以了解，付費的關鍵有兩個：

1. Block 用完了
2. 需要更進階的共筆功能與權限設定

### Block 限制

Block 的用量，介面上會有圖表提醒，只是怎樣才算一個 block？Notion 的概念跟 [Ruby](https://www.notion.so/6c1b009e-919d-48a0-923c-4fc811602cb4) 一樣－－萬物皆物件，一個物件就是一個 block。舉幾個例子：

* `/` 彈出來的物件清單，都是算一個 block。
* 一個頁面裡面是空的，算一個 block。
* 一個頁面裡面有一個段落，則是兩個 blcok。

雖然可以靠開無限個 workspace，讓 block 達到理論上的無上限，但對於可能會塞入成千上百的 block 的重度使用者來說，這是不能接受的。

### Notaion 的權限設計

在多人共筆時，有可能會發生誤刪的狀況，共筆功能與權限設定正是解決這個問題所設計的！然後 Notion 也很巧妙的把這個功能設計成付費功能。

Notion 對於一個頁面的權限做了以下的分級：

1. Private 頁面只限作者本人可以看得到
2. Can Read 可以看得到頁面
3. Can Comment 包含了 2 的權限，加上可以評論
4. Can Edit 包含了 3 的權限，加上可以編輯頁面
5. Full Access 包含了 4 的權限，加上能刪除頁面、移動頁面、增加成員與設定

而角色則是有下列三種

1. Guest 可以讓指定的使用者，對指定頁面有指定的權限
2. Member 可以讓指定的使用，對指定的 workspace 有指定的權限
3. Admin 擁有 workspace 所有權限

其中 Can Edit 權限與 Member 角色是被封印的。而 Personal 可以解鎖 Can Edit 權限、Team 可以再加解鎖 Member 角色

先不考慮 block 的問題，若平常共筆大家都用得好好的話，倒沒什麼必要花錢解鎖。除非有協作者常常搞破壞才需要解鎖 Personal 使用 Can Edit 限制破壞者的權限，並有 30 天的歷史記錄回顧。

而如果要共用的協作者和頁面會時常調整的話，則會需要解鎖 Team 的 Member 功能。

## Database 的設計問題

Database 對我來說，會遇到兩個問題：

1. 裡面的項目不會出現在樹狀結構裡。
2. 沒有 1 to 1 的對應，或是類似 MySQL view 可以把資料用不同的方法呈現。
3. 沒有 union。

第一個問題，主要是因為 Database 裡面的 page ，還能繼續再塞 page。若需要從左邊的樹狀結構找到更底層的 page 是會有困難的。

第二個問題是因為同份資料在不同的 page 會有不同的資料呈現。比方說，如果現在這個部落格是使用 Database 的。若想加草稿區的 view，就會被所有人看光光。但這在目前的權限設計上應該很難達成。

第三個問題是因為我有個使用情境是，會議記錄 list 會有兩個不同類型的觀看者，所以我建了兩個 list。但我需要一個整合兩個會議記錄的 list，這是現有功能辦不到的。

## 即使如此，還是很好用

就 [Notion 初體驗](https://www.notion.so/dd0903ea-68b2-4854-9bfa-0b941c158909) 提到的筆記類型軟體，也只有 Notion 做出 Database 的功能，只有使用情境不符的問題，並沒有其他對手實作出競爭功能。概觀而言，Notion 對我來說，依然是一個值得花錢訂閱的服務。

歡迎使用我的[邀請連結](https://www.notion.so/?r=36767f1a722a41c5a970e0a533b6a564)加入 Notion。加入可以拿到 $10 bonus，我也能拿到 $5 bonus 哦。

# 參考資料

* [新手第三课：秒懂Notion权限与付费体系](https://zhuanlan.zhihu.com/p/65780461)
