---
layout: post
title: iThome Container Summit 2016 心得
---

<img width="400" src="/images/container-summit-2016.jpg" alt="Container Summit 2016">

續上次參加 [DevOps Summit 2016](http://devopssummit.ithome.com.tw/) 後，知道了本活動的訊息。因為已迷上使用 Docker ，於是蠻早就決定要參加 Container Summit 2016 。

今年 container 主題圍繞著幾個重點：

1. Orchestration 容器調度
2. Security 安全
3. Monitoring 監控
4. 企業導入 container 經驗分享

感覺主辦單位也有特別選擇議程主題

## Orchestration

大約在 2014 年尾時，小弟才發現 Vagrant & Docker ，也發現 Docker 優於 Vagrant 的地方與劣勢。當時覺得 Docker 雖然資源利用率很高，但是 container 管理機制卻不是那麼直覺方便。而 2015 年中的時候意外發現到 Rancher ，而之後就學習 Rancher 並了解 Orchestration 的概念至今。

同樣地，其他的 orchestration 目標，都是讓人們可以很簡單地佈署並管理 container 。

* 目前台灣業界是導入 [Kubernetes][] 居多，有 Google 長期使用的背景，加上 GCP 可以很好的整合，小弟認為它會是 production 最佳選擇
* [Swarm][] 有著 Docker 原廠維護的加持光環，加上 1.12 版整合到 engine 後，簡化非常多。未來相信會漸漸追上 Kubernetes 。
* [DC/OS][] 介面看 demo 很棒，也有一鍵安裝 stack 的介面可以使用
* [Rancher][] 有著易上手的安裝方法和介面，小弟私心會推新手入門

不同的 orchestration 有著不同的屬性。一套適合需求的系統，才會是最佳選擇。

目前小弟有使用 Rancher 在測試環境上，並有在 local 把玩過 Swarm 和 [Minikube](https://github.com/kubernetes/minikube) 。未來應該會往 Kubernetes 學習，感覺 Google 長年運行 container 的經驗，絕對值得花時間深入研究一番。

## Security

佈署管理 container 很簡單，但企業決定一套系統可行性的最後一刻時，維運工程師們都會問「這安全嗎？」

來自上海道客網路科技的孫宏亮，他的回應很有趣：「它還真的是不安全」，但他又提到 Docker 官方：「它真的很安全」只是官方的意思是 Security by default 。

講者提到 Docker 最大的目的，主要都在使用上要好用，而安全其次。雖然是這麼說， Docker 也是有對安全性做了一番功夫，比方說實作了 Linux 上， cgroup 、 namespace 、 capability 底層實作，但因為小弟這塊才剛開始看，只知道這些關鍵字和大概是做權限限制而已。雖然 Docker 不是為安全而生，但它還是可以透過一些做法來增加安全性，比方說：

* 限制 container 的系統資源
* TLS 加密
* 不要在 container 用 root 執行服務
* 檔案權限限制，該有的權限就給，不該給就別給
* 不必要的檔案就移除，參考葉大的[為什麼要追求極簡化的 Docker image？](http://school.soft-arch.net/blog/247272/why-minimal-docker-images)

接著講者還 demo 如何在 container 裡控制 Host 的 Docker Engine ，看到了才突然體會到 Docker 不注意安全的話有多可怕...

## Monitoring

又，佈署管理 container 很簡單，但要如何知道整個系統的健康程度呢？

Monitoring 也是一門藝術，所以小弟選擇聽，來自趨勢科技資深軟體工程師陳岳澤的「建構 Container 監控系統的藝術」

講者提到了收集資訊的方式

- Blackbox vs Whitebox
- Pull Mode vs Push Mode

與三種內容

- Operation System
- Application
- Business Logic

與三種格式

- Metrics
- Events
- Logs

另外還有一堆工具

- Collect
  - Collectd
  - cAdvisor
  - Telegraf
  - Fluentd
- Store
  - InfluxDB
  - Elasticserach
- Visualize
  - Grafana
  - Kibana
- Alert
  - Icinga2

> Prometheus 講者歸類成 all-in-one solution ，而講者的主題是客製化 Monitoring ，同時也藉此說明一些 Monitoring 要關注的重點

以前都以為 Monitoring 是把 Grafana 打開，看到一堆看似很厲害的圖表就叫 Monitoring 。聽完才發現原來 Monitoring 有它需要專注的重點，而且有一部分是需要 RD 配合記錄的。

老話一句，因為對 Linux 不是很熟悉，所以對於 OS 層的資訊收集不是很了解。有機會的話，想試看看 Elasticserach + Grafana 的做法，去 Monitoring PHP Application 的狀況。

## 經驗分享

最後， container 的這麼厲害，是否有企業成功導入呢？

小弟認為 Docker 的易用性與標準化，可以簡化環境一致性的難度。最簡單的一個導入方向：讓開發環境與測試環境一致。以前公司算有成功導入 Rancher 到測試環境，並讓 RD 可以自行佈署環境到測試環境。但因為 container 建議需要有的 immutable 特性，在應用程式裡暫時無法實現，所以有些地方還是需要 RD 人工處理。

但事實上，小弟認為導入 container 最大的困難，在於團隊是否適用。葉大的「 Docker 導入：障礙與對策」如同簡介「以限制理論的思維方式，剖析 Docker 導入的痛點及障礙，並逐一開出藥方，協助你降低導入 Docker 的阻力。」，葉大不講工具技術，而是講觀念和思維。

坦白說，以前都會覺得別人可以，為什麼我們公司不行。後來才漸漸發現，不是不行，而是有更適合的方法。別人的經驗與使用的工具，只是幫助找出適合自己的方法。在找到之後，就會變成專屬於我們公司經驗，並可以再分享給更多人參考。

葉大這兩個月在社群常常說：「請回到還沒有 Docker 的時代，重新思考你的問題！」，一開始覺得有點莫名奇妙，後來才發現其實一點也沒錯， Docker 畢竟只是換個工具和觀念在做目前的事。不管有沒有 Docker ，該做的東西還是得做，並沒有多也沒有少！

## 心得

Docker / Container 技術建議 Dev / Ops 必學，它還在成長中，永遠學不完。但有趣的是，很多基本概念一直都沒變，像 immutable ， AWS 專家在教 EC2 也有提到 immutable 特性建議要有，這樣才能隨開即用，剛好跟 container 建議的特性不謀而合。只是企業要導入到什麼程度，還是要看需求。

最後，兩天接受了不少經驗知識，感謝各講者與前輩分享和主辦單位的辛勞，也感謝 DevOps Taiwan 成員不嫌棄小弟廢話太多XD ，明年 Container Summit 2017 見！

## 相關連結

回憶參考連結

- [Container Summit 2016 - 邁向下個 IT 架構的 Container](http://note.drx.tw/2016/09/container-summit-2016-it-container.html) @凍仁的筆記
- [iThome Container Summit 2016 Day 1 簡易筆記心得](http://blog.chengweichen.com/2016/09/ithome-container-summit-2016-day-1.html) @艦長，你有事嗎？
- [iThome Container Summit 2016 Day 2 簡易筆記心得](http://blog.chengweichen.com/2016/09/ithome-container-summit-2016-day-2.html) @艦長，你有事嗎？

官方相關連結

- [Container Summit 航向容器新世界](http://containersummit.ithome.com.tw/)
- [Container Summit 2016 相關訊息](http://beta.hackfoldr.org/containersummit2016)

[Kubernetes]: http://kubernetes.io/
[Swarm]: https://docs.docker.com/swarm/
[DC/OS]: https://dcos.io/
[Rancher]: http://rancher.com/
