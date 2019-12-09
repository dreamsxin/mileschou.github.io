---
title: 環境安裝
layout: collections
---

環境設置的方法很多，除了直接在 Host 環境安裝外，還能使用虛擬機或容器的隔離特性，在 Host 上執行應用

## Docker

Docker 是目前隔離特性的首選，如果會使用 Docker 的話，也是懶人首選之一

先上 [Docker Hub][] 看一下有提供哪些版本，再 pull 下來，以下選擇超輕量版本 `3.5-alpine`

    $ docker pull python:3.5-alpine
    $ docker run -it python:3.5-alpine   # 預設會執行 python 指令互動介面

接著建議用 [Docker Compose][] ，可以簡化許多指令操作， `docker-compose.yml` 的範例如下

```yml
version: '2'
services:
  app:
    image: python:3.5-alpine
    stdin_open: true
    tty: true
    working_dir: /usr/src/app
    ports:
      - 8000:8000
    volumes:
      - .:/usr/src/app
```

如果要打開互動式操作可以下這個指令：

    $ docker-compose run --rm app

如果要執行 py 檔的話，可以下這個指令：

    $ docker-compose run --rm app python app.py

要測試不同版本的 python 可以直接改 yml 檔即可，還蠻方便的

[Docker Hub]: https://hub.docker.com/_/python/
[Docker Compose]: https://docs.docker.com/compose/
