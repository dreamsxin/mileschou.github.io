---
title: JSON Web Algorithms
layout: collections
---

數位簽章的密碼學演算法選擇，可以參考 [RFC 7518](https://tools.ietf.org/html/rfc7518#section-3) ， 

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

## 如何產 key

### RS256

[RFC](https://tools.ietf.org/html/rfc7518#section-3.3) 裡提到了：

> A key of size 2048 bits or larger MUST be used with these algorithms.

必須要 2048 bits 以上的 key，實際可以使用下面的指令產生：

```
# generate private key
openssl genrsa -out rs256-private.pem 2048

# extatract public key from it
openssl rsa -in rs256-private.pem -pubout > rs256-public.pem
```

### ES256

[RFC](https://tools.ietf.org/html/rfc7518#section-3.4)

參考 Google 的[說明](https://cloud.google.com/iot/docs/how-tos/credentials/keys#generating_an_es256_key)，可以使用下面的指令產生

```
# generate private key
openssl ecparam -genkey -name prime256v1 -noout -out es256-private.pem

# extatract public key from it
openssl ec -in es256-private.pem -pubout -out es256-public.pem
```

### 驗證方法

以 PHP 為例，如果要使用 ES256 需先安裝 `gmp`。 

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
