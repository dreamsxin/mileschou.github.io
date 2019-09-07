---
layout: post
title: Hello World! Docker Swarm
---

初次把玩 [Docker Swarm][] 筆記，以下使用 [Docker Machine][] + Docker 1.12 + VirtualBox

## Create Machine

首先第一步要做的，當然就是要開開開開機器了

    $ docker-machine create -d virtualbox node1
    $ docker-machine create -d virtualbox node2
    $ docker-machine create -d virtualbox node3

然後，為了方便了解，所以去找了一下視覺化工具，看看到底 Swarm 做了什麼

* https://github.com/ManoMarks/docker-swarm-visualizer
* https://github.com/JulienBreux/docker-swarm-gui

需要先選定一台當 manager 然後在上面用標準的 Docker 指令啟動，如要在 node1 上啟動：

    $ eval $(docker-machine env node1)
    $ docker run -it -d -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock julienbreux/docker-swarm-gui:latest
    # 或是另一套
    # docker run -it -d -p 8080:8080 -e HOST=192.168.99.100 -e PORT=8080 -v /var/run/docker.sock:/var/run/docker.sock manomarks/visualizer
接著開 node1 上的 8080 port 會看到一片空的網頁

## Initial Swarm and Join Swarm

接著上面的操作，因為選定是 node1 要當 manager ，所以先切換到 node1 下初始化指令

```
$ eval $(docker-machine env node1)
$ docker swarm init --advertise-addr 192.168.99.100  # 因為 VirtualBox 預設會起兩個網路介面
Swarm initialized: current node (8o4fxwxu8e4zqhxn4vco7rguj) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join \
    --token SWMTKN-1-3dmqscpgn6jwxk5o7zlmum5i2655um6bv1lgmtcztp48h4fh4n-bgmembhgaok4lhjzo2adxwsho \
    192.168.99.100:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

這邊會提示說 Swarm 啟動，並開啟 2377 port 監聽。目前的 node 是 manager ，其他要加進來的會是叫 worker 。 Swarm 支援多 manager 模式，所以也有加 manager 的方法。如果有注意 GUI 的話，會發現出現一個新的 node1 區塊。這是 node1 裡面 container 的視覺化。

不過目前只是單純練習 Manager / Worker 模式，接著切換到 node2 node3 下剛剛提示的指令

```
$ eval $(docker-machine env node2)
$ docker swarm join --token SWMTKN-1-3dmqscpgn6jwxk5o7zlmum5i2655um6bv1lgmtcztp48h4fh4n-bgmembhgaok4lhjzo2adxwsho 192.168.99.100:2377
This node joined a swarm as a worker.
$ eval $(docker-machine env node3)
$ docker swarm join --token SWMTKN-1-3dmqscpgn6jwxk5o7zlmum5i2655um6bv1lgmtcztp48h4fh4n-bgmembhgaok4lhjzo2adxwsho 192.168.99.100:2377
This node joined a swarm as a worker.
```

GUI 這時又會多兩個 `node2` `node3` 區塊，目前因為都沒有 container 所以會是一片空地。

## Start Service

這裡找一個最簡單最小的 Service 來練習： `nginx:alpine` 。如果要對整個 cluster 作操作的話，需要先切換到 Manager 。

使用 `docker service create` 可以建立 container 。

Warning: 雖然用法跟 run 很像，但是看 `--help` 的參數比 run 少了很多，要再多試才知道。

```
$ docker service create --name web -p 8000:80 nginx:alpine
4r0x9rts2adklf3tt9816av50
```

這時有趣的來了，假設 Container 在 node1 ，那開 `http://<node1_ip>:8000/` 會看到畫面是很合理的。但是神奇的是，另外兩台機器也都看得到哦！

再來 Swarm 當然也有 scaling

```
$ docker service scale web=30
web scaled to 30
```

接著容器會佈滿三個 node ，但是 port 都不會衝突，而且三個 node 實際都是分散到各個 container 裡的

更新的範例

```
$ docker service update --image nginx web
web
```

[Docker Swarm]: https://docs.docker.com/swarm/
[Docker Machine]: https://docs.docker.com/machine/
