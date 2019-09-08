---
layout: post
title: Log 層級的小筆記
---

最近需要對 log 做點調整，因此研究了一下 RFC 對 log 的想法為何。

首先先列出跟 log 有關 RFC 為何：

* [RFC 3164](https://tools.ietf.org/html/rfc3164)
* [RFC 3195](https://tools.ietf.org/html/rfc3195)
* [RFC 5424](https://tools.ietf.org/html/rfc5424)

參考[別人的文章](https://blog.csdn.net/fishmai/article/details/51838681)，簡單來說原本大家就是各自做，後來出了 RFC 3164 提醒大家應該怎麼做，但它用 UDP，後來出了 RFC 3195 說要用 TCP；在更後來出了 RFC 5424 則是為了取代 RFC 3164 而出的。  

只是今天要筆記的主要是 *level*。

RFC 5424 使用了嚴重度（*Severity*）的關鍵字作為層級的標準，總共分成 8 個層級，與簡單的說明如下：

| Numerical Code | Severity |
| --- | --- |
| 0 | Emergency: system is unusable |
| 1 | Alert: action must be taken immediately |
| 2 | Critical: critical conditions |
| 3 | Error: error conditions |
| 4 | Warning: warning conditions |
| 5 | Notice: normal but significant condition |
| 6 | Informational: informational messages |
| 7 | Debug: debug-level messages |

> 參考 https://tools.ietf.org/html/rfc5424#section-6.2.1

原本預期能在 RFC 上看到不同層級的說明，但它又說（https://tools.ietf.org/html/rfc5424#appendix-A.3）

> Because severities are very subjective, a relay or collector should not assume that all originators have the same definition of severity.

確實每個人或每個應用程式，對於錯誤的感受不同，分類就會有所不同。

不過還好它對 Emergency 和 Debug 倒是有建議：

> Most importantly, messages designed to enable debugging or testing of software should be assigned Severity 7.  Severity 0 should be reserved for messages of very high importance (like serious hardware failures or imminent power failure).

任何為了除錯或測試階段使用的 log，都是 7；而 0 應該保留給系統人員決定。

而再回到各層級的定義，因為 PSR-3 也有提供 comment 說明，綜合 RFC 上的 comment，這裡主觀的總結如下：

| Severity | Severity | Example |
| --- | --- | --- |
| Emergency| 系統不可用 | 硬體錯誤、停電 |
| Alert | 必須要立即處理的錯誤，需要觸發立即訊息通知相關人員處理 | 資料庫當機 |
| Critical | 重要錯誤，需要被注意的錯誤 | 某個元件不能使用、非預期的例外 |
| Error | 一般錯誤，不需要立即處理，但需要被記錄與監視 | 未定義的變數（註） | 
| Warning | 特殊訊息，但它不是錯誤 | API 接受資料規格帶有攻擊資訊（如 XSS），但可被過濾成可用的資料 |
| Notice | 正常但需被注意的訊息 | API 接受資料規格不正確，但可被過濾成可用的資料 |
| Informational | 一般訊息 | SQL 記錄 |
| Debug | 僅在除錯或測試階段使用的訊息 | 除錯訊息 |

> 註：對 PHP 來說，未定義變數可能是 notice 錯誤，但對上線來說，可能會是 error 的來源。
