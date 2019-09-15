---
title: 身分驗證的定義
---

引用 OpenID Connect Core 所提到的術語（terminology）：

> Process used to achieve sufficient confidence in the binding between the Entity and the presented Identity.

直譯可能比較難理解，比較白話的說法就是：綁定（binding）使用者所宣稱的身分（identity）到某個實體（entity）的過程，且我們對這個過程的結果是充分信任的。

### 什麼是實體？

實體是一個抽象概念，它代表的是系統上一個明確的身分，比方說資料庫裡面的某個會員，或是 Linux 系統裡面的某個 user，或是現實生活裡的「人」或「法人」，都是這樣的概念。

而像 guest 或 anonymous 等，則是比較像角色（role），並非真實的存在。

### 什麼是綁定？

綁定指的是使用者表明了他的身分，而我們在存放資料庫裡找到對應的實體，並信任使用者代表這個實體，即為上文所稱的綁定。

### 小範例

舉一個最簡單的例子：MySQL root 沒設定密碼。因為沒有密碼，因此只要使用者提出要登入 root「實體」，MySQL 就能通過身分驗證，並信任該使用者為 root。

上面的例子可能太誇張，再舉個相較安全一點點的例子：Linux root 有設定密碼，但開放 ssh 登入 root。對攻擊者而言，只要了解 Linux 系統，即會知道系統必定有個「實體」叫 root，接著 ssh 登入方法是使用帳號密碼，這意味著只要猜密碼即可完成綁定，並讓系統信任攻擊者為 root。

而再舉現代行動裝置比較普遍的驗證方法：生物辨識技術（biometrics），如對 iPhone 而言，要知道操作者是不是持有者的方法，可以取得指紋，並在資料庫尋找對應的實體做綁定。

## 安全疑慮

現實生活會發生的偽造文書，在電腦通訊領域也會有類似或更多安全上的問題。常見的登入系統大多使用帳號密碼驗證，包括銀行也是類似的介面，但事實上，一些常見的攻擊手法如：

* Replay attack - [重送攻擊](https://zh.wikipedia.org/wiki/%E9%87%8D%E6%94%BE%E6%94%BB%E5%87%BB)
* Phishing - [網路釣魚](https://zh.wikipedia.org/wiki/%E9%92%93%E9%B1%BC%E5%BC%8F%E6%94%BB%E5%87%BB)
* Man-in-the-middle attack - [中間人攻擊](https://zh.wikipedia.org/wiki/%E4%B8%AD%E9%97%B4%E4%BA%BA%E6%94%BB%E5%87%BB)

這幾個攻擊手法有一個共同的特色是：無法確保訊息來源的可靠性。像*重送攻擊*是利用 server 無法確保訊息來源真的是該訊息持有人的前提下，所能做的攻擊；*網路釣魚*剛好相反，使用者無法確保網頁真的是該服務所提供的內容；*中間人攻擊*就更不用說了，兩邊都不知道中間有個人在搞鬼。

因此，在討論網頁的身分驗證時，常會思考的安全性問題都在確認請求是真的請求，回應是真的回應：

* 請求真的是該使用者所發出的請求？有沒有可能被竄改？有沒有機會造假？
* 回應真的是 server 的回應？有沒有可能被竄改？有沒有機會造假？

## 參考資料

* [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html)
* [身分驗證](https://en.wikipedia.org/wiki/Authentication) | 維基百科
* [生物辨識技術](https://en.wikipedia.org/wiki/Biometrics) | 維基百科
