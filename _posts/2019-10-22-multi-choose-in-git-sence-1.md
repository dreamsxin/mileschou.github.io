---
title: Git 情境題之多選題 Part 1
layout: post
tags:
- git
---

會有這篇文章是因為，很無聊想到同一個情境可以用很多解法來做，所以就順便記錄起來了。

## 移動 branch 的位置

Branch `some` 從 commit `A` 移到 commit `B` 有兩種做法：

```
# HEAD 不在想要移的 branch 上
git checkout master
git branch -f some B

# HEAD 在想要移的 branch 上（若 working directory 有修改的話，可以用 git stash）
git checkout some
git reset --hard B
```

## 本地端 branch 想 rebase 遠端某個 branch

Branch `some` rebase 到遠端 `origin` 最新的 `target` branch，有四種做法：

```
# 一個指令打天下
git checkout some
git pull --rebase origin target

# 指令分解法
git checkout some
git fetch
git rebase origin/target

# 小心確認法
git checkout target
git pull
git checkout some
git rebase target

# 一步一腳印法
git checkout target
git cherry-pick [commits]
git branch -f some HEAD
```
