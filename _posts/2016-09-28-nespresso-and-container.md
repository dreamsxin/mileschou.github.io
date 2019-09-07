---
layout: post
title: Nespresso and Container
---

<img width="400" src="/images/nespresso.jpg" alt="Nespresso 新的限量口味">

今天跟往常一樣，打開了咖啡機並放膠囊開始懶人煮咖啡法。突然間靈光一閃：這膠囊根本就是 container 最佳實務啊！

接著無聊去想了一下相似的地方，順便去看了一下 container 的特性，也算有複習到了

- Container is immutable ；膠囊也是，雖然無法像純軟體一樣精確，但確實膠囊的目標也是要做到 immutable
- Container 很輕量；膠囊也是，是膠囊咖啡機比較佔空間 XD
- Container 啟動很快速；膠囊也是（其他家不清楚，至少我的 Nespresso 還蠻快的）
- Container 用過即丟；膠囊也是（我都丟回收站 XD ）
- Container 有不同的大廠在去義規格；膠囊也是
- 各 Container 之間的執行是互相獨立的；膠囊也是
- Container 如果具備宿主的 root 權限時，將會很危險；膠囊也是（你敢讓膠囊有控制你的咖啡機的權限嗎 XD ）
- Container 某些資訊要由環境變數給它；膠囊也是，我都買義式濃縮咖啡當美式在喝的，要是膠囊本身也決定了這個參數，那真的會不大想用 ...

以後如果解釋什麼是 container 的話，就可以用膠囊咖啡機來說明了 XD

## 參考相關連結

* [在 Docker Container 裡應該避免的 10 件事](https://blog.fntsr.tw/articles/2016/03/06/10-things-to-avoid-in-docker-containers/)
* [Rancher - 傻瓜也會用的容器集群管理](http://s.itho.me/containersummit/2016/0921/trackb/Rancher-%E5%82%BB%E7%93%9C%E4%B9%9F%E6%9C%83%E7%94%A8%E7%9A%84%E5%AE%B9%E5%99%A8%E9%9B%86%E7%BE%A4%E7%AE%A1%E7%90%86.pdf)
