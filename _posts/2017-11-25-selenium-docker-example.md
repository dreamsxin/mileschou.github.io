---
layout: post
title: Selenium Docker Example
---

這是一個簡單的 [Selenium Docker] 範例

首先先直接開 Container ：

```bash
docker run -d -p 4444:4444 -p 5900:5900 selenium/standalone-chrome-debug:3.7.1
```

其中 port `4444` 是跟 Selenium 溝通用的， port `5900` 則是 VNC ，密碼固定為 `secret` 。

啟動完成之後，可以先打開 VNC 來觀察有沒有動靜。

下一步要呼叫 Selenium 做事了，以下使用 [CodeceptJS][] ，先安裝套件：

```bash
npm install -g codeceptjs webdriverio
```

接著初始化它

```bash
mkdir -p /path/to/your/project
cd /path/to/your/project
codeceptjs init
```

初始化的過程會問很多問題，大部分都用預設值，下面這個問題選 `WebDriverIO`

```
? What helpers do you want to use? WebDriverIO
```

另外還有一個問題是要問驗證的目標網站，先用本部落格吧

```
? [WebDriverIO] Base url of site to be tested https://mileschou.github.io/
```

接著建立測試檔

```bash
codeceptjs gt
```

它會要為測試取個名字，就先亂取吧！接著會多一個測試的樣版檔：

```javascript
Feature('Some');

Scenario('test something', (I) => {

});
```

下面的 Scenario 區塊就是可以寫測試的地方了，比方說可以這樣寫：

```javascript
Feature('Some');

Scenario('test something', (I) => {
  I.amOnPage('/');
  I.wait(5);
  I.see('Miles');
  I.see('A Developer Notes');
  I.amOnPage('/selenium-docker-example/')
  I.wait(5);
  I.see('Selenium');
});
```

CodeceptJS 的特點是，它把測試的寫法調整成比較人性化，看測試程式就知道要驗證的東西，非常好用

最後，存檔並執行它吧：

```bash
codeceptjs run
```

如果一切正常，可以看得到 VNC 的 Chrome 自動起動與關閉，以及看得到驗證成功或失敗，這樣就串成功了！

原始碼可以參考[這個 repo](https://github.com/MilesChou/docker-selenium-example)

[CodeceptJS]: http://codecept.io/
[Selenium Docker]: https://hub.docker.com/u/selenium/
