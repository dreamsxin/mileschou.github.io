---
title: Faker（6）－－自己 Provider 自己來
---

一個套件好不好用，除了它本身的功能要很厲害之外，我們也能藉由擴充功能的方法來讓套件更強大，那就再好也不過了。這正是[開關原則][SOLID 之 開關原則（Open-close principle）]的精神，而 Faker 正是符合此精神的套件。

就讓我們一起來證明它吧！

## 世間情產生器

[世間情][]是一部八點檔連續劇，我們來試看看能不能做出一個*世間情產生器*，可以產生世間情的角色名字。

照 Faker 的設計，我們只需要寫一個 Provider，再加入 `Generator` 即可。

我們會有兩種做法，一種是全新的 Provider 與方法，另一種是繼承 `Person` 並覆寫原本的 `name` 方法。

## 全新 Provider 

這個方法非常簡單，先寫 Provider，並定義好公開要讓 Generator 參考的方法（`loveName`）：

```php
use Faker\Provider\Base;

class Love extends Base
{
    protected static $name = array(
        '杜瑞峰',
        '郭佳佳',
        '羅元浩',
        '柯展弘',
        '趙怡琇',
        // ...
    );

    public function loveName()
    {
        return static::randomElement(self::$name);
    }
}
```

接著在 Generator 產生後，再使用 `addProvider` 方法加入即可：

```php
$generator = Faker\Factory::create('zh_TW');
$generator->addProvider(new Love($generator));
```

最後即可用剛剛公開的方法 `loveName`，來產生世間情角色的名字：

```php
echo $generator->loveName . PHP_EOL;
```

## 繼承原有的 Provider

全新的方法可以全都自己定義，因此可以定的非常簡單，像上面只有取得名字。而原有的 `Person` 有姓有名，我們必須要想辦法讓這些方法都能回傳世間情角色的名字，相對就有點麻煩。

以下讓我們一步一步達成它吧！首先先繼承台灣版的 `Persion`：

```php
class Love extends \Faker\Provider\zh_TW\Person
{
}
```

接著，我們有以下目標的行為要覆寫：

```php
echo $generator->name;              // 產生一個角色全名
echo $generator->firstName;         // 產生一個名
echo $generator->firstNameMale;     // 產生一個男性角色名
echo $generator->firstNameFemale;   // 產生一個女性角色名
echo $generator->lastName;          // 產生一個姓
```

先從 `lastName`、`firstName` 與 `name` 的關係開始。我們 `name` 想要角色的全名，但 `lastName`、`firstName` 的卻是要它們拆開的，這代表我們可能需要一個二維陣列來存放這些資料：

```php
protected static $name = array(
    array('杜', '瑞峰'),
    array('郭', '佳佳'),
    array('羅', '元浩'),
    array('柯', '展弘'),
    array('趙', '怡琇'),
    array('朱', '卉喬'),
    array('謝', '萱萱'),
    array('謝', '曉婷'),
    array('江', '曉婷'),
    array('謝', '子奇'),
    array('杜', '仁德'),
    array('方', '思瑤'),
    array('李', '雅欣'),
    ...
);
```

接著 `name` 方法就非常簡單，把陣列組合起來就行了：

```php
public function name($gender = null)
{
    $nameArray = static::randomElement(static::$name);

    return $nameArray[0] . $nameArray[1];
}
```

`lastName` 與 `firstName` 則是把陣列的值各別回傳：

```php
public function firstName($gender = null)
{
    $nameArray = static::randomElement(static::$name);

    return $nameArray[1];
}

public function lastName()
{
    $nameArray = static::randomElement(static::$name);

    return $nameArray[0];
}
```

再來下一個課題就是要把男女分開了，直接從 $name 的資料拆分成兩種資料：

```
protected static $maleName = array(
    array('杜', '瑞峰'),
    array('羅', '元浩'),
    array('柯', '展弘'),
    array('謝', '子奇'),
    array('杜', '仁德'),
);

protected static $femaleName = array(
    array('郭', '佳佳'),
    array('趙', '怡琇'),
    array('朱', '卉喬'),
    array('謝', '萱萱'),
    array('謝', '曉婷'),
    array('江', '曉婷'),
    array('方', '思瑤'),
    array('李', '雅欣'),
);
```

`name` 與 `firstName` 需要做點調整，先用最蠢的方法完成：

```php
public function name($gender = null)
{
    if ($gender === static::GENDER_MALE) {
        $nameArray = static::randomElement(static::$maleName);
    } elseif ($gender === static::GENDER_FEMALE) {
        $nameArray = static::randomElement(static::$femaleName);
    } else {
        $nameArray = static::randomElement(array_merge(static::$maleName, static::$femaleName));
    }

    return $nameArray[0] . $nameArray[1];
}

public function firstName($gender = null)
{
    if ($gender === static::GENDER_MALE) {
        $nameArray = static::randomElement(static::$maleName);
    } elseif ($gender === static::GENDER_FEMALE) {
        $nameArray = static::randomElement(static::$femaleName);
    } else {
        $nameArray = static::randomElement(array_merge(static::$maleName, static::$femaleName));
    }

    return $nameArray[1];
}
```

再來有相同的程式碼是一個明顯的[壞味道][開發者能察覺的壞味道（Bad Smell）]，我們來重構，把它抽出方法再呼叫它：

```php
protected function loveName($gender)
{
    if ($gender === static::GENDER_MALE) {
        return static::randomElement(static::$maleName);
    } elseif ($gender === static::GENDER_FEMALE) {
        return static::randomElement(static::$femaleName);
    } else {
        return static::randomElement(array_merge(static::$maleName, static::$femaleName));
    }
}

public function name($gender = null)
{
    $nameArray = $this->loveName($gender);

    return $nameArray[0] . $nameArray[1];
}

public function firstName($gender = null)
{
    $nameArray = $this->loveName($gender);

    return $nameArray[1];
}
```

而男女性的呼叫相信大家應該都了解了：

```php
public static function firstNameMale()
{
    $nameArray = static::randomElement(static::$maleName);

    return $nameArray[1];
}

public static function firstNameFemale()
{
    $nameArray = static::randomElement(static::$femaleName);

    return $nameArray[1];
}
```

再來假設我們原本在用 Faker，只要有這個 class，把它放到 Generator 後，就可以產生世間情的角色名字了！

Faker 的介紹到此結束，它是一個值得參考設計的好套件，大家有空也可以翻翻。

## 參考資料

* [SOLID 之 開關原則（Open-close principle）][] - 看到 code 寫成這樣我也是醉了，不如試試重構？
* [開發者能察覺的壞味道（Bad Smell）]

[開發者能察覺的壞味道（Bad Smell）]: https://github.com/MilesChou/book-refactoring-30-days/blob/master/docs/day04.md
[SOLID 之 開關原則（Open-close principle）]: https://github.com/MilesChou/book-refactoring-30-days/blob/master/docs/day08.md
[世間情]: https://zh.wikipedia.org/wiki/%E4%B8%96%E9%96%93%E6%83%85
