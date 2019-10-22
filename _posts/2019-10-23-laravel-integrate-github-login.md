---
title: 使用 Laravel 串接 GitHub
layout: post
tags:
- laravel
- github
---

Laravel 串接 GitHub 或一些常見的第三方服務是非常方便的。

首先先安裝 Socialite 套件：

```
composer require laravel/socialite
```

接著新增一組設定在 `config/service.php` 裡

```
'github' => [
    'client_id' => env('GITHUB_CLIENT_ID'),
    'client_secret' => env('GITHUB_CLIENT_SECRET'),
    'redirect' => 'http://localhost:8000/callback',
],
```

因為這裡有新的 env，所以 `.env.example` 和 `.env` 都必須新增變數：

```
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
```

接著設定都完備了，開兩個 route，一個是要 redirect 到 GitHub 的，另一個則是 GitHum 授權完要拿 code 回來換 token 的。

```
Route::get('/login', function () {
    return Socialite::driver('github')
        ->redirect();
});

Route::get('/callback', function () {
    $user = Socialite::driver('github')->user();

    dump($user);
});
```

如上，`dump()` 即可拿到使用者資訊（user info）。
