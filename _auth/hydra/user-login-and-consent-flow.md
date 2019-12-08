---
title: User Login and Consent Flow
layout: collections
---

> 參考 [ORY Hydra - OAuth 2.0 & Open ID Connect](https://www.ory.sh/docs/hydra/oauth2)

這是 ORY Hydra （下簡稱 Hydra）的登入與授權流程。了解它，才知道該如何使用 Hydra。

## OAuth 2.0 與 Open ID Connect

Hydra 是一個 OAuth 2.0 Authorization 服務，同時也是 OpenID Connect 服務。有些人會誤以為這兩個服務的職責，是要保存使用者資料，並讓使用者登入。事實上，它們的任務是把使用者的憑據（credentials），轉換成 *Access Token* 或 *OpenID Connect ID Token*。這就有點像使用 cookie 儲存 session 資訊一樣，但它更加有彈性，也適合用在第三方應用程式。

Hydra 不存放使用者資料，如 profile、username、password。這些資料會被放在其他服務，而 Hydra 會使用 **User Login and Consent Flow** 的流程，來串接 Hydra 與這些服務。這個流程會使用 HTTP redirect 來將 authorization request 導去 **Login Provider** 與 **Consent Provider**。這兩個 provider 是可以自行實作的，可以是既有服務，或是新的應用程式。

概觀而言，這兩個服務的職責如下：

* *Login Provider* 要認證使用者，並驗證使用者輸入的帳號或密碼是否正確。
* *Consent Provider* 是使用者授權，它決定 OAuth 2.0 應用程式拿到的 Access Token 具有什麼樣的權限

另一個重要的觀念是有關 OAuth 2.0 Scope。

通常多數開發者，都會把 OAuth 2.0 Scope 與一般的存取控制（Access Control），像是 *RBAC*（Role Based Access Control）或 *ACL*（Access Control Lists）搞混。

在內部的存取控制是在限制使用者在系統能做什麼事。比方說系統管理員有所有的權限，而一般會員只能存取個人資訊。而相對的 OAuth 2.0 Scope 並不是在描述使用者能在系統做什麼事。

OAuth 2.0 Scope 在說的是使用者允許 Client 能代表使用者存取使用者的資源。比方說，使用者可以允許 Client 讀取使用者的照片，但不允許 Client 代表使用者上傳照片。所以，OAuth 2.0 Scope 表達的並不是使用者的權限。它表達的是 Client 可以代表使用者做哪些事。

以上是 Hydra 兩個最重要的部分概述。而 Hydra 主要功能是實作了 OAuth 2.0 與 OpenID Connect 的規範，以及 IETF OpenID Foundation 的規範。

下面將會介紹如何把現有的會員系統跟 Hydra 串接，這樣就能成為 OAuth 2.0 與 OpenID Connect 的 Provider，就像 Google、Facebook 一樣。

> 注意：以下章節建立在讀者已了解 [OAuth 2.0](/src/oauth2) 與 [OpenID Connect](/src/oidc) 的前提下。

## 專有名詞

在開始講解細節前，先我們了解一些術語。這些術語其實就分散在 OAuth 2.0 或 OpenID Connect 協定裡。

這裡會使用更簡單的用詞來取代原本的用詞。

* *resource owner* 擁有資源者，一般指的就是使用者。
* *OAuth 2.0 Authorization Server* 是一個實作 OAuth 2.0 協定的服務，本文指的正是 Hydra。
* *resource provider* 是一個提供使用者資源的服務。
* *OAuth 2.0 Client* 是想存取使用者資源的服務。
* *Identity Provider* 是認證提供者，提供使用者的登入與註冊服務。也有可能會有管理介面可以管理使用者帳號與權限。
* *User Agent*，一般指的是瀏覽器。
* *OpenID Connect* 是一個建構在 OAuth 2.0 上的協定，主要是加上身分驗證的協定。

典型的 OAuth 2.0 流程如下：

1. 開發者先在授權服務（Authorization Server，也就是 Hydra）上註冊 OAuth 2.0 Client，目的是要取得使用者資料。
2. 授權服務會要求使用者授權 OAuth 2.0 Client 存取使用者資料。
3. 使用者被轉導至授權服務。
4. 授權服務確認使用者身分，並要求使用者授權 OAuth 2.0 Client 某些權限。
5. 授權服務發行 token 給 OAuth 2.0 Client，以便可以代表使用者存取資源。

## 認證使用者與要求同意（consent）

前面已概述了 Hydra 的任務，這裡將會說明 *User Login and Consent Flow* 流程的細節。

這個流程會執行一連串的轉導，經過 Login Provider 認證使用者，再到 Consent Provider 授權。這兩個 Provider 都將由開發者自由實作。比方說用 NodeJS 實作可以接 /login 與 /consent 的 HTTP Server，這就能當作是 Login / Consent Provider 了。

一圖勝萬言，直接來看官方提供的循序圖：

![](https://www.ory.sh/images/docs/hydra/login-consent-flow.png)

細節如下：

1.  首先 OAuth 2.0 Client 需要啟動一個 OpenID Connect 流程，實務上的做法是把使用者轉導到 `http://hydra/oauth2/auth?client_id=...&...`。
2.  Hydra 如果發現使用者尚未驗證的話（也就是沒有 session 或 cookie 等），會把使用者轉導到 Login Provider。上面有提過，Login Provider 將由開發者自行實作，這裡就可以呈現登入介面給使用者，如帳密輸入之類的畫面。這時候的 URL 會類似像這樣：`http://login-service/login?login_challenge=1234...`。
3.  Login Provider 將會自己處理登入流程。登入成功後，需要把使用者的資訊（如 user ID）傳送給 Hydra。接著再轉導回 Hydra：`http://hydra/oauth2/auth?client_id=...&...&login_verifier=4321`。
4.  回到 Hydra 後，Hydra 會再把使用者導去 Consent Provider，如：`http://consent-service/consent?consent_challenge=4567...`。
5.  Consent Provider 將會顯示要求使用者授權 OAuth 2.0 Client 哪些權限（也就是 OAuth 2.0 Scope）的介面。
6.  Consent Provider 在使用者完成授權時，會發出另一個請求給 Hydra，讓 Hydra 知道 Scope 有哪些。接著再轉導回 Hydra：`http://hydra/oauth2/auth?client_id=...&...&consent_verifier=7654...`。
7.  接著再依 Hydra 的轉導，回到 OAuth 2.0 Client。
8.  此時，使用者已完成認證與授權。最後，Client 即可跟 Hydra 要 Access、Refresh、ID Token。

這樣的設計允許開發者對登入系統，和授權頁的行為，能有更完整的控制（如，2FA）

## 實作 Login & Consent Provider 

上面已經說明整個流程概觀，接著要說明如何實作這兩個 Provider。

### OAuth 2.0 Authorize Code Flow

OAuth 2.0 Authorize Code Flow 是由 OAuth 2.0 Client 啟動流程的。通常是產生一個像這樣的 URL：

```
https://hydra/oauth2/auth?client_id=1234&scope=foo+bar&response_type=code&...
```

然後再由 OAuth 2.0 Client 轉導使用者到這個 URL。

### Hydra 處理授權 request

當使用者到了 Hydra 這個 URL，它會檢查是否有之前成功登入的 session cookie 記錄。除此之外，還會處理 `id_token_hint`、`prompt`、`max_age` 等相關參數。

接著，使用者會被導到 Login Provider。這個路徑將會採用 `OAUTH2_LOGIN_URL` 的環境設定。舉例來說，下面是設定與導頁的實際例子：

```
OAUTH2_LOGIN_URL=https://login-provider/login

https://login-provider/login?login_challenge=1234
```

**注意**：不管這個使用者有沒有成功登入的 session cookie，或是否需要認證，Hydra 都會將使用者轉導至 Login Provider。

### Login Provider

在處理 Hydra 過來的請求，如 `https://login-provider/login?login_challenge=1234` 時，首先要使用 `login_challenge` 的值，來呼叫 Hydra 所提供的 API 來取得身分驗證請求（authentication request）相關的資訊。

Laravel + Hydra SDK 程式碼範例如下：

```php
public function login(Request $request, AdminApi $adminApi)
{
    $challenge = $request->post('challenge');

    $response = $adminApi->acceptLoginRequest($challenge);
    
    // ...
}
```

`$response` 可以拿到的 JSON object，內容如下：

```
{
    // 是否要跳過 Login Provider，如果是 true 的話，意味著 Hydra 已經成功驗證過這個使用者，並不需要顯示 UI 了
    "skip": true|false,

    // 已成功驗證的使用者 ID，只有當 skip 是 true 的時候才會有值
    "subject": "user-id",

    // 啟動此流程的 OAuth 2.0 client
    "client": {"id": "...", ...},

    // 啟動流程的請求 URL
    "request_url": "https://hydra/oauth2/auth?client_id=1234&scope=foo+bar&response_type=code&...",

    // OAuth 2.0 Client 要求的 Scope
    "requested_scope": ["foo", "bar"],

    // OpenID Connect 請求資訊
    "oidc_context": {"ui_locales": [...], ...}
}
```

> 詳情可以查[官方 API 文件](https://www.ory.sh/docs/hydra/sdk/api)

如果 skip 是 `false`，就可以使用帳密表單，或是其他身分證明來提示使用者登入。

如果 skip 是 `true`，則**不應該**顯示任何介面，而是使用呼叫 Hydra API 來接受登入請求。在這個步驟，也可以做更新使用者登入次數或相關記錄，甚至是自定義的商務邏輯。但一樣，**不應該**顯示任何介面。

接受請求的程式碼，可能會像下面這樣：

```php
$body = [
    // 驗證後的使用者 ID，如果 skip 是 true 的話，這裡必須要代入上面所拿到的 subject
    'subject' => '...',
    
    // 如果設定為 true，這次驗證成功的 session 將會由 Hydra Response 來讓使用者存在 cookie 中
    // 未來相同的使用者請求，skip 將會是 true。相對的，前一個 response 拿到的 skip 是 true 的話，則這個設定就無效
    'remember' => '(boolean)true|false',
    
    // Cookie 的時效，當 remember 是 true 的時候，這個設定才會有作用
    'remember_for' => 3600,
    
    // 標示該次登入的驗證方法，有可能是 2FA 或使用生物測量資訊
    'acr' => '...',
];

// Response 會有 `redirect_to` 欄位，裡面的 URL 即是使用者要轉導的下一站
$response = $adminApi->acceptLoginRequest($challenge, new AcceptLoginRequest($body));

redirect()->away($response->getRedirectTo());
```

下面這是拒絕登入的範例：

```php
$body = [
    // 這裡要帶入 ERROR ID，如 `login_required` 或是 `invalid_request`
    'error' => '...',
    
    // 錯誤的詳細內容
    'error_description' => '(boolean)true|false',
];

// Response 會有 `redirect_to` 欄位，裡面的 URL 即是使用者要轉導的下一站
$response = $adminApi->acceptLoginRequest($challenge, new AcceptLoginRequest($body));

redirect()->away($response->getRedirectTo());
```

### 使用者授權

到了這個階段，我們已經可以知道使用者是誰了，接著必須要問使用者，是否要授權這個 OAuth 2.0 Client 的授權請求。首先，會先檢查使用者過去是否有授權過。如果使用者從未授權，或是 OAuth 2.0 Client 要求過去未授予的權限，則必須要顯示畫面讓使用者授權。

這個過程類似登入流程，首先會被轉導至 Consent Provider。將會採用 `OAUTH2_CONSENT_PROVIDER` 的環境設定，下面是設定與導頁的實際例子：
                                                                         
```
OAUTH2_CONSENT_PROVIDER=https://consent-provider/consent

https://consent-provider/consent?consent_challenge=1234
```

與登入流程相同，無論是否有授權，或是有效的 session，都一定會轉導至 Consent Provider。

### Consent Provider

Consent Provider 在處理 request 的時候，首先要使用 `consent_challenge` 跟 Hydra API 取得資訊。

下面是 Laravel + Hydra SDK 的程式碼範例：

```php
public function consentPage(Request $request, AdminApi $adminApi)
{
    $challenge = $request->get('consent_challenge');

    $response = $adminApi->getConsentRequest($challenge);
}
```

`$response` 將會有下面的資訊：

```
{
    // 如果是 true ，代表之前使用者已授權此 OAuth 2.0 Client
    "skip": true|false,

    // 使用者 ID
    "subject": "user-id",

    // 啟動此流程的 OAuth 2.0 client
    "client": {"id": "...", ...},

    // 啟動流程的請求 URL
    "request_url": "https://hydra/oauth2/auth?client_id=1234&scope=foo+bar&response_type=code&...",

    // OAuth 2.0 Client 要求的 Scope
    "requested_scope": ["foo", "bar"],

    // OpenID Connect 請求資訊
    "oidc_context": {"ui_locales": [...], ...}
}
```

如果 `skip` 是 `true` 的話，不應該顯示使用者介面。取而代之的是，應該要接受（或拒絕）同意請求。一般來說，除非有充分的理由拒絕請求，不然應該要接受請求。

如果 `skip` 是 `false` 的話，則需要顯示授權頁，並使用 `requested_scope` 的資訊顯示使用者必須授權的權限列表。如果 OAuth 2.0 Client 是第一方的 Client，有些情境下會跳過這一步－－因為這個 Client 跟認證系統是同一方的應用程式。

假設使用者同意請求，則跟登入流程類似：

```php
$body = [
    // 使用者授權的權限列表，通常都比 Client 要求一樣，或比較少，很少會有比 Client 要求的多
    'grant_scope' => [],

    // 如果設定為 true，這次驗證成功的 session 將會由 Hydra Response 來讓使用者存在 cookie 中
    // 未來相同的使用者請求，skip 將會是 true。相對的，前一個 response 拿到的 skip 是 true 的話，則這個設定就無效
    'remember' => '(boolean)true|false',
    
    // Cookie 的時效，當 remember 是 true 的時候，這個設定才會有作用
    'remember_for' => 3600,

    // 這個 session 資訊，將會作為額外的資訊設定到 Access Token 或 ID Token 裡 
    session: {
        // 設定到 Access Token 和 Refresh Token，以及未來 refresh 後的 Token
        // 注意：
        // 執行 OAuth 2.0 Challenge Introspection 的任何人都可以看到這些資料。如果只有內部服務使用就沒有太大問題，但第三方可以存取的話，則得小心使用。
        access_token: { ... },

        // 設定到 OpenID Connect ID token。任何有權存取 ID Challenge 都有辦法讀取到此內容，請小心使用。
        id_token: { ... },
    }
];

// Response 會有 `redirect_to` 欄位，裡面的 URL 即是使用者要轉導的下一站
$response = $adminApi->acceptConsentRequest($challenge, new AcceptConsentRequest($body));

redirect()->away($response->getRedirectTo());
```

一樣可以拒絕授權，就跟登入流程一樣：

```php
$body = [
    // 這裡要帶入 ERROR ID，如 `login_required` 或是 `invalid_request`
    'error' => '...',
    
    // 錯誤的詳細內容
    'error_description' => '(boolean)true|false',
];

// Response 會有 `redirect_to` 欄位，裡面的 URL 即是使用者要轉導的下一站
$response = $adminApi->rejectConsentRequest($challenge, new rejectConsentRequest($body));

redirect()->away($response->getRedirectTo());
```

若同意授權並轉導回 OAuth 2.0 Client 後，則 OAuth 2.0 的流程就到此結束。

## 撤銷 Consent and Login Session

### Login

我們可以撤銷登入的 session 和 cookie，讓使用者在下一次啟動 OAuth 2.0 流程時，重新進行身分認證。使用 REST API 即可達成：

```
DELETE /oauth2/auth/sessions/login/{user}`
```

> [參考文件](https://www.ory.sh/docs/hydra/sdk/api#invalidates-a-user-s-authentication-session)

**注意**：此做法將會刪除所有設備中的所有 cookie。

### Consent

類似地，我們可以基於應用程式撤銷授權的 session 和 cookie，撤銷時，會把所有存取權限撤銷，並更新 token。

```
# 撤銷所有 session
DELETE to/oauth2/auth/sessions/consent/{user}

# 撤銷特定 client 的 session
DELETE to/oauth2/auth/sessions/consent/{user}/{client}
```

> 對應的文件為 [Revokes all previous consent sessions of a user](https://www.ory.sh/docs/hydra/sdk/api#revokes-all-previous-consent-sessions-of-a-user) 與 [Revokes consent sessions of a user for a specific OAuth 2.0 Client](https://www.ory.sh/docs/hydra/sdk/api#revokes-consent-sessions-of-a-user-for-a-specific-oauth-20-client)

## OAuth 2.0 Scope

OAuth 2.0 Scope 定義了使用者授予 token 有什麼樣的權限。比方說，「可以存取公開資訊」、「可以上傳圖片」等等。這會在 Consent Provider 階段授權。

另外，Hydra 有預先定義了幾個 OAuth 2.0 Scope：

* `offline` 和 `offline_access`：如果希望拿到 refresh token 的話，請加入這個 scope。
* `openid`：如果希望執行 OpenID Connect 請求的話，請加入這個 scope。

## OAuth2 Token Introspection

OAuth2 Token Introspection 是 IETF [RFC 7662](https://tools.ietf.org/html/rfc7662) 標準。這是在定義 Resource Server 該用什麼樣的方法，來跟授權服務器確定 Token 的有效狀態。

Hydra 有提供 API `POST /oauth2/introspect`，詳情可以翻閱[文件](https://www.ory.sh/docs/hydra/sdk/api#introspect-oauth2-tokens)；也有提供 CLI，執行方法如下：

```
hydra token introspect <token>
```
