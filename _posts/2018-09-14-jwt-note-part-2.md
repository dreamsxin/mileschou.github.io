---
layout: post
title: JWT 筆記（二）－－演算法
tags: [jwt]
---

JWT 的加密與雜湊演算法選擇，可以參考 [RFC 7518](https://tools.ietf.org/html/rfc7518#section-3)。 

| "alg" Value | Digital Signature or MAC Algorithm | Implementation Requirements |
| --- | --- | --- |
| HS256 | HMAC using SHA-256 | Required |
| HS384 | HMAC using SHA-384 | Optional |
| HS512 | HMAC using SHA-512 | Optional |
| RS256 | RSASSA-PKCS1-v1_5 using SHA-256 | Recommended |
| RS384 | RSASSA-PKCS1-v1_5 using SHA-384 | Optional |
| RS512 | RSASSA-PKCS1-v1_5 using SHA-512 | Optional |
| ES256 | ECDSA using P-256 and SHA-256 | Recommended+ |
| ES384 | ECDSA using P-384 and SHA-384 | Optional |
| ES512 | ECDSA using P-521 and SHA-512 | Optional |
| PS256 | RSASSA-PSS using SHA-256 and MGF1 with SHA-256 | Optional |
| PS384 | RSASSA-PSS using SHA-384 and MGF1 with SHA-384 | Optional |
| PS512 | RSASSA-PSS using SHA-512 and MGF1 with SHA-512 | Optional |
| none | No digital signature or MAC performed | Optional |

## Terms

老實說，這裡有很多不清楚的名詞，今天來查查吧！

* 非對稱性加密 - 使用兩把金鑰來做加解密，公鑰 *public key* 加密，私鑰 *private key* 解密，也因此稱為「非對稱」
* 對稱性加密 - 使用同一把金鑰 *secret* 來做加解密
* *MAC* - [Message authentication code](https://zh.wikipedia.org/wiki/%E8%A8%8A%E6%81%AF%E9%91%91%E5%88%A5%E7%A2%BC) ，參考 wiki ：這在密碼學中，是指一小段資訊。它可以用特定演算法，從原有的一包資訊來產生，目的是確定原本的資訊沒有被更改過。
* *HMAC* - [Hash-based Message Authentication Code](https://zh.wikipedia.org/wiki/%E9%87%91%E9%91%B0%E9%9B%9C%E6%B9%8A%E8%A8%8A%E6%81%AF%E9%91%91%E5%88%A5%E7%A2%BC) ，這是加上 secret 來產生 MAC 的方法。此演算法的公式可以在 [RFC 2104](https://tools.ietf.org/html/rfc2104) 裡找到
* [RSA](https://zh.wikipedia.org/wiki/RSA%E5%8A%A0%E5%AF%86%E6%BC%94%E7%AE%97%E6%B3%95) - 一種非對稱性加密演算法
* RSASSA-PKCS1-v1_5 - 指的是 [Section 8.2 of RFC 3447](https://tools.ietf.org/html/rfc3447#section-8.2)
* RSASSA-PSS - 指的是 [Section 8.1 of RFC 3447](https://tools.ietf.org/html/rfc3447#section-8.1)
* ECDSA - The Elliptic Curve Digital Signature Algorithm

## 如何產 key

因需求，應該會使用 `RS256` 或 `ES256`，接下來來看 key 如何產

### RS256

[RFC](https://tools.ietf.org/html/rfc7518#section-3.3) 裡提到了

> A key of size 2048 bits or larger MUST be used with these algorithms.

必須要 2048 bits 以上的 key，來參考[別人](https://gist.github.com/Holger-Will/3edeea6855f1d69a5368871bce5ea926)怎麼產

```
# generate private key
openssl genrsa -out rs256-private.pem 2048

# extatract public key from it
openssl rsa -in rs256-private.pem -pubout > rs256-public.pem
```

### ES256

[RFC](https://tools.ietf.org/html/rfc7518#section-3.4)

參考 Google 的[說明](https://cloud.google.com/iot/docs/how-tos/credentials/keys#generating_an_es256_key)

```
# generate private key
openssl ecparam -genkey -name prime256v1 -noout -out es256-private.pem

# extatract public key from it
openssl ec -in es256-private.pem -pubout -out es256-public.pem
```

### 驗證方法

使用 PHP，如果要使用 ES256 需先安裝 `gmp`。 

Debian 系列：

```
apt-get install libgmp-dev
```

CentOS 系列：

```
yum install gmp-devel
```

Alpine 系列：

```
apk add gmp-dev
```

PHP 測試程式碼，使用 [`lcobucci/jwt`](https://github.com/lcobucci/jwt) 套件

```php
<?php

use Lcobucci\JWT\Signer\Ecdsa;
use Lcobucci\JWT\Signer\Rsa;

include 'vendor/autoload.php';

$signer = Ecdsa\Sha256::create();

$privateKey = file_get_contents(__DIR__ . '/es256-private.pem');
$publicKey = file_get_contents(__DIR__ . '/es256-public.pem');

$signature = $signer->sign('something', new \Lcobucci\JWT\Signer\Key($privateKey));
$isValid = $signer->verify($signature, 'something', new \Lcobucci\JWT\Signer\Key($publicKey));

echo ($isValid ? 'OK' : 'fail') . PHP_EOL;

$signer = new Rsa\Sha256();

$privateKey = file_get_contents(__DIR__ . '/rs256-private.pem');
$publicKey = file_get_contents(__DIR__ . '/rs256-public.pem');

$signature = $signer->sign('something', new \Lcobucci\JWT\Signer\Key($privateKey));
$isValid = $signer->verify($signature, 'something', new \Lcobucci\JWT\Signer\Key($publicKey));

echo ($isValid ? 'OK' : 'fail') . PHP_EOL;
```
