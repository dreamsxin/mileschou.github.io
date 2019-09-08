---
layout: post
title: GCPUG Taiwan Meetup 21 會後心得
---

今天很幸運地，可以參加 LIVEhouse.in 的分享。

為什麼說幸運？因為昨天才知道這個訊息，當然早就額滿了。在此非常感謝主辦單位特別給我三張票。

[活動傳送門](http://gcpugtw.kktix.cc/events/201601102)

## Live Streaming

*Browny Lin / LIVEhouse.in*

傳送門

- [LIVEhouse.in](https://livehouse.in/)
- [Strass.io](https://straas.io/)
- [簡報](http://go-talks.appspot.com/github.com/StraaS/StraaS-stream-service/slides/live-streaming-service-on-gcp/live-streaming-service-on-gcp.slide#4)

這次分享的主要主題是 Streaming，老實說我對這個領域是完全陌生。但從這次的分享，可以了解一些大方向的架構。

首先講者直接說明一般直播的行為：

1. 先在 CMS 上建立直播頻道
2. 取得 token / key
3. 直播軟體上輸入 token / key ，即可把 streaming 打上去
4. CMS 可以 preview ，覺得 ok 即可 public

> VOD (Video on demand) 的流程大同小異，變成先上傳檔案而已

講者提到使用 Strass.io 的好處：對開發人員，直播的功能都會由 Strass.io 解決，開發人員可以更專心在其他功能上

### Strass.io 核心

[GitHub 原始碼](https://github.com/StraaS/StraaS-stream-service)

Live 通常還是接受 RTMP 居多，VOD 則可以接受很多格式，但輸出都會是 HLS / MP4

流程在簡報的 [13](http://go-talks.appspot.com/github.com/StraaS/StraaS-stream-service/slides/live-streaming-service-on-gcp/live-streaming-service-on-gcp.slide#13) / [14](http://go-talks.appspot.com/github.com/StraaS/StraaS-stream-service/slides/live-streaming-service-on-gcp/live-streaming-service-on-gcp.slide#14) 頁會有圖片說明。從流程圖可以了解，Transcoder 的任務被設計的很單純，就是做轉檔。而任務調配或是錯誤處理等等，都會由 Middleware 處理。在簡報後面有提到它的主要任務：

- 安排適合的機器做 transcode
- 斷線重連
- 上傳影片品質不同，預期會用不同的 transcoder (講者的設計是普通與高效兩種)
- 備援機制
- Service 之間的溝通
- 新舊機器交替
- 資源回收
- Monitor & Alert

### Stack

這邊講者提到他們使用的 GCP 服務

- Compute Engine (當然是 Transcoder)
- Datastore / CloudSQL
- Storage (放靜態影片檔)
- PubSub (任務排隊)
- BigQuery (資料分析，推測應該是做 UX 之類的)

最近在學 AWS 也順便對應一下 AWS 的服務

- EC2
- DynamoDB / RDS
- S3
- SQS
- [Kinesis Analytics](https://aws.amazon.com/tw/kinesis/analytics/) (這個我不大確定，看介紹跟 BigQuery 很像)

接著當然也有 IDC service

- Metrics / Alert service
- Billing service
- Consensus service (有點類似 transcoder 的 lock 功能)
- Data Analysis service

### Summary

最後講者提到了這個架構的特色與未來期望

- 錯誤處理複雜
- 頻寬和 transcoder 的平衡
- 再做更好的模組化
- 直播很多功能都已經是必備，現在直播的服務重點會在：**直播是否能跟外面世界互動**

## Lighting talk

### 中國很恐怖！GCP上自建長城保護自己的服務

[簡報傳送門](https://speakerdeck.com/peihsinsu/gcpug-dot-tw-201611-meetup-best-practices-for-ddos-protection-and-migration-on-gcp)

*Louie CK / MiTAC Cloud Lead*

主題在講防底層的攻擊，這邊只記錄了一些防 DDOS 服務：

- [Akamai](https://www.akamai.com/) (也是最貴的)
- [Imperva Incapsula](https://www.incapsula.com/)
- [Brocade](http://www.brocade.com/en.html)
- [Arbor](https://www.arbornetworks.com/)
- [NexusGuard](https://www.nexusguard.com/)

> [CloudFlare](https://www.cloudflare.com/) 目前範圍還不是很大，所以沒被講者列入

### 自幹DNS Proxy over GCP

[簡報傳送門](https://speakerdeck.com/edwardchuang/dns-proxy-on-gcp-and-gke)

*Edward Chuang / GCPUG.TW co-organizer*

簡單來說，雲端上的機器太多太雜，有時要連線佈署搞不好會連錯台就死定了，所以講者做了一個本機的 DNS port to GCE API

這樣就會有些優點如下

- 不用更新 zone File
- 可以寫在程式
- 也可以找內部 IP

原始碼放在 [GitHub](
https://github.com/edwardchuang/gcp-dns-proxy)

### 玩大資料不可不知 - Google PubSub簡介

[簡報傳送門](https://speakerdeck.com/peihsinsu/gcpug-dot-tw-201611-meetup-pubsubjian-jie)

*Simon Su / GCPUG.TW co-organizer*

這是大資料可以使用的服務，它是個 Queue，聽介紹跟 Amazon SQS 很像

> 印象中 SQS 如果資料不刪，過一段時間會被刪除。待確認

```
# 自幹大數據服務
Client -> Infra -> Kafka -> Spark -> Cassandra

# 使用 GCP 服務
Client -> Compute engine -> PubSub -> DataFlow -> BigQuery
```

使用 PubSub 的方法有 push mode / pull mode，講者有流程圖，但目前沒得到分享，所以只能 pass。但重點是它的訊息不會被刪，直到你對 message ack 才會被刪

講者有提到 PubSub 的特色：它不是 FIFO，跟 Amazon SQS 一樣，但他提到很重要的原因：

大數據的處理，應該是要被設計成非序列處理（或非同步處理），才會有辦法快。或許 PubSub / SQS 這樣設計，也是讓開發人員會不自覺做出符合大數據的可擴展架構。原本還有點嫌棄，但聽到講者這麼說，才知道我是有必要去使用，才能讓程式有一定的可擴展程度。

## Finally

個人是比較偏愛 GCP，因為 UI 好看，但符合公司需求還是要 AWS，因此工作需求還是會以學習與使用 AWS 為主。

最後，除了我外，兩位朋友也都大有收獲，再次感謝主辦單位贊助！

## References

* [GCP 頂級合作夥伴 LIVEhouse.in](https://gcp.expert/)
* [GCPUG.TW Facebook](https://www.facebook.com/groups/GCPUG.TW/)
