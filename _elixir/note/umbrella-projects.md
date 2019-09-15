---
title: Umbrella Projects
layout: collections
---

有時專案可能會非常大，基於模組化的想法，會希望拆成小專案來維護。Mix 有提供這樣的機制，讓專案可以切分成多個小專案。

## 建立專案

首先，先建立一個 Umbrella Projects 專案，方法很簡單，只要下以下指令即可：

```
$ mix new some_umbrella --umbrella

* creating .gitignore
* creating README.md
* creating mix.exs
* creating apps
* creating config
* creating config/config.exs

Your umbrella project was created successfully.
Inside your project, you will find an apps/ directory
where you can create and host many apps:

    cd some_umbrella
    cd apps
    mix new my_app

Commands like "mix compile" and "mix test" when executed
in the umbrella project root will automatically run
for each application in the apps/ directory.
```

這裡會有兩個資料夾：

* `apps` 子專案目錄
* `config` 主專案的設定目錄

接著提示有提到可以進 apps 目錄建新的專案：

```
cd apps
mix new my_app1

cd .. 
mix new my_app2

cd .. 
mix new my_app3
```

接著就會有像下面的層次

```yaml
some_umbrella:
- apps:
  - my_app1:
    - 普通的專案目錄 
  - my_app2:
    - 普通的專案目錄
  - my_app3:
    - 普通的專案目錄
- config
```

在這個配置下，子專案因為是普通的專案，所以一定是可以正常地使用 Mix 建置。而主專案也可以使用 Mix 指令：

```
mix compile
```

包括 IEx 也能正常使用：

```
iex -S mix
```
