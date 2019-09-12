---
title: Faker（1）－－假文產生器
---

在開發階段時，取名是讓開發者覺得非常困擾的任務之一。

當然，變數或函式命名必須得好好想想，不然容易造成別人看不懂的[技術債][]。但有一種很想亂打就好，但系統會要求你不能亂打的－－測試資料。

比方說，前兩天上測試環境要註冊帳號看到：

```
miles 這個使用者名稱已有人使用，請試試其他名稱。
```

對厚，上禮拜才用這個帳號，那換 `miles123` 試試：

```
miles123 這個使用者名稱已有人使用，請試試其他名稱。
```

可…可惡，又重覆了！那 `miles482842781937382383724` 總沒用過吧

```
miles482842781937382383724 可以使用哦，揪咪 ^.<
```

系統是在揪咪什麼啦！算了，總之而言，註冊好了。

（十分鐘後…）

嗯…剛剛的帳號名稱是什麼？忘了，再註冊一個吧！（上面的故事再循環一次）

又或者是，系統上會有 100 多個姓「麥」的，然後有 50 個都叫「爾斯」，當測試環境出問題的時候，看到「麥爾斯」出錯，還真的不知道是哪一個在搞鬼。

## 登登登登！假．文．產．生．器！

https://www.youtube.com/watch?v=ecjQvXCsVl4

這套件的功能，就是產生假資料，常見的姓名當然難不倒它：

```php
$faker = Faker\Factory::create();

echo $faker->name;
```

再來看看它還可以產生什麼：

```php
// 地址
echo $faker->address;

// 電話
echo $faker->phoneNumber;

// email
echo $faker->email;

// 密碼
echo $faker->password;

// IP
echo $faker->ipv4;

// User Agent
echo $faker->userAgent;

// 信用卡
echo $faker->creditCardNumber;

// 廢文
echo $faker->text;

// ...
```

各式各樣的假資料都能產生，不僅如此，它還支援多語系：

```php
$faker = Faker\Factory::create('en_US');
echo "$faker->name\n";
$faker = Faker\Factory::create('zh_TW');
echo "$faker->name\n";
$faker = Faker\Factory::create('ja_JP');
echo "$faker->name\n";
$faker = Faker\Factory::create('ko_KR');
echo "$faker->name\n";
```

輸出可能如下：

```
Robert Becker
帥哲哲
野村 千代
옥형민
```

什麼！區區一個假文產生器怎麼這麼自戀，叫什麼「帥哲哲」！？沒關係，這幾天讓我們一起來一探假文產生器的奧妙，到時要叫「金城武」還是「金秀賢」都隨開發者高興了！

## 參考資料

這幾天將會使用 [Faker v1.7.1](https://github.com/fzaninotto/Faker/tree/v1.7.1) 做範例。

[技術債]: https://github.com/MilesChou/book-refactoring-30-days/blob/master/docs/day02.md
