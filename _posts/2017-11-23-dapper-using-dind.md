---
layout: post
title: Dapper Using DinD
---

[Dapper][] 最近不支援 MacOS 10.13.1，可是最近常常需要 Dapper，該怎麼辦？

想到一個解法就是，反正 Dapper 只依賴 Docker，乾脆用 DinD 解決算了XD

剛好 Dapper 也有 [Docker CLI 版](https://hub.docker.com/r/rancher/dapper/)。就來用它吧！

先執行一個 DinD 的 server

```bash
docker run --privileged -d --name dind docker:1.12.1-dind
```

再來切換工作目錄，進入 Dapper 的 Docker CLI

```bash
docker run --rm -it --link dind:docker -v `pwd`:/source -w /source rancher/dapper:1.12.1
```

工作目錄下，放著 `Dockerfile.dapper`，這時使用 Dapper 的條件都有了，就下吧XD

```
dapper
```

缺點是，因為隔了一層 container，硬碟速度或網路速度多少會慢了點，不過短解就這樣先撐過吧。 

[Dapper]: https://github.com/rancher/dapper
