---
title: Installation
layout: collections
---

> 參考[官網](https://www.ory.sh/docs/hydra/configure-deploy)

## Using Docker

Hydra 有提供 [Docker Repo](https://cloud.docker.com/repository/docker/oryd/hydra)：

```
docker run --rm -it --entrypoint hydra oryd/hydra:v1.0.0-rc.9 help
```

## MacOS

使用 [Homebrew](https://brew.sh/) 安裝：

```
brew tap ory/hydra
brew install ory/hydra/hydra
hydra help
```

## Linux

直接下載 binary 即可。

```
curl https://raw.githubusercontent.com/ory/ory/master/install.sh | bash -s -- -b .
./hydra

# 放到全域空間下
sudo mv ./hydra /usr/local/bin/
```

## References

* [官方網站](https://www.ory.sh/docs/hydra/configure-deploy)
