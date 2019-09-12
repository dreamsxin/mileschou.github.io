---
title: 分析 Auth（3）－－客製化驗證機制
---

之前在分析套件都是只有在看 Laravel 原始碼，沒有任何客製化的範例，而今天會來示範如何客製化驗證機制。

雖然 Laravel 已經實作得很完整了，但不同的情境下，可能還是需要寫些客製化程式。

舉個情境：既有的 Credentials 資料來源無法使用 [DatabaseUserProvider][] 或 [EloquentUserProvider][] 讀取，如，資料是 PHP Array：

```php
$credentials = [
    // 帳號 => 密碼
    'admin' => 'password',
    'miles' => '123456'
];
```

## 客製化 Authenticatable

因資料的結構改變，所以 [Authenticatable][] 也可能需要自己寫一個。先來看一下它的介面：

```php
// 取得 ID 時，所會需要用到的 key / col 名稱等識別名稱 
public function getAuthIdentifierName();

// 取得 ID
public function getAuthIdentifier();

// 取得密碼的內容
public function getAuthPassword();

// 取得 remember token
public function getRememberToken();

// 設定 remember token
public function setRememberToken($value);

// 取得 remember token 時，所會需要用到的 key / col 名稱等識別名稱
public function getRememberTokenName();
```

很明顯，因為例子裡的資料並沒有 remember token，所以需要來實作一下：

```php
class User implements Authenticatable
{
    private $attributes;
    
    public function __construct($attributes)
    {
        $this->attributes = $attributes;
    }
    
    public function getAuthIdentifierName()
    {
        return 'id';
    }

    public function getAuthIdentifier()
    {
        return $this->attributes[$this->getAuthIdentifierName()];
    }

    public function getAuthPassword()
    {
        return $this->attributes['password'];
    }

    public function getRememberToken()
    {
        // 不使用 remember token，回傳空字串
        return '';
    }

    public function setRememberToken($value)
    {
        // 不使用 remember token，pass
    }

    public function getRememberTokenName()
    {
        // 不使用 remember token，回傳空字串
        return '';   
    }
}
```

事實上，也可以使用 [GenericUser][]，但它的 `getRememberToken()` 可能會發現 key 不存在的錯誤：

```php
public function __construct(array $attributes)
{
    $this->attributes = $attributes;
}

public function getRememberToken()
{
    return $this->attributes[$this->getRememberTokenName()];
}

public function getRememberTokenName()
{
    return 'remember_token';
}
```

如果對 guard 或 controller 的原始碼不熟的話，比方說哪裡突然有呼叫到，也許就會發生非預期的結果。

當然這也是能解決的，等等下面看 provider 是如何做的就會了解。

## 客製化資料提供者（provider）

在 UML 圖裡，有一個角色是專門提供資料的－－[UserProvider][]，它的介面如下：

```php
// 使用 ID 取得 Authenticatable 實例
public function retrieveById($identifier);

// 透過 ID 與 remember token 取得 Authenticatable 實例
public function retrieveByToken($identifier, $token);

// 更新 remember token
public function updateRememberToken(Authenticatable $user, $token);

// 透過 credentials 取得 Authenticatable 實例
public function retrieveByCredentials(array $credentials);

// 透過 Authenticatable 來驗證 credentials
public function validateCredentials(Authenticatable $user, array $credentials);
```

DatabaseUserProvider 與 EloquentUserProvider 都實作了這個介面，即然這兩個實作都不能用的話，就自己寫一個：

```php
class ArrayUserProvider implements UserProvider
{
    private $credentials = [
        'admin' => 'password',
        'miles' => '123456'
    ];

    public function retrieveById($identifier)
    {
        if (!isset($this->credentials[$identifier])) {
            return null;
        }
        
        $attributes = [
            'id' => $identifier,
            'password' => $this->credentials[$identifier],
            // 如果要用 GenericUser 的話，加下面這行即可
            'remember_token' => '',
        ];
        
        return new User($attributes);
    }

    public function retrieveByToken($identifier, $token)
    {
        // 不使用 remember token，所以回傳 null
        return null;
    }

    public function updateRememberToken(Authenticatable $user, $token)
    {
        // 不使用 remember token，所以不做事
        return null;
    }

    public function retrieveByCredentials(array $credentials)
    {
        // 如果沒有給 id 欄位的話，無法找到對應的 user
        if (!isset($credentials['id'])) {
            return null;
        }
        
        $attributes = [
            'id' => $credentials['id'],
            'password' => $this->credentials[$credentials['id']],
            // 如果要用 GenericUser 的話，加下面這行即可
            'remember_token' => '',
        ];
        
        return new User($attributes);
    }

    public function validateCredentials(Authenticatable $user, array $credentials)
    {
        // 如果沒有給 password 欄位的話，等於驗證失敗
        if (!isset($credentials['password'])) {
            return false;
        }
        
        return $user->getAuthPassword() === $credentials['password'];
    }
}
```

到目前為止，自定義的 Array 認證功能就算客製化完成了，只要最後設定一下即可。首先要先註冊 ArrayUserProvider：

```php
// 在 boot 階段做即可
Auth::provider('array', function() {
    return new ArrayUserProvider();
});
```

接著加上設定：

```php
return [
    'defaults' => [
        'guard' => 'web',
        'passwords' => 'users',
    ],

    'guards' => [
        'web' => [
            'driver' => 'session',
            'provider' => 'users',
        ],
    ],

    'providers' => [
        'users' => [
            // 這裡的 driver 使用 array 即可對應上面註冊的 ArrayUserProvider
            'driver' => 'array',
        ],
    ],
];
```

最後，預設的 [AuthenticatesUsers][] 是使用 `email` 當作登入名稱的，可以覆寫 `username()` 方法的值為 `id`，即可運作正常。

[AuthenticatesUsers]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Foundation/Auth/AuthenticatesUsers.php
[Authenticatable]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Auth/Authenticatable.php
[DatabaseUserProvider]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Auth/DatabaseUserProvider.php
[EloquentUserProvider]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Auth/EloquentUserProvider.php
[GenericUser]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Auth/GenericUser.php
[UserProvider]: https://github.com/laravel/framework/blob/v5.7.6/src/Illuminate/Contracts/Auth/UserProvider.php
