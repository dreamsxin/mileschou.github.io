---
title: Serializations
layout: collections
---

訊息傳遞所要使用的序列化方法如下：

1. Query String Serialization
2. Form Serialization
3. JSON Serialization

這裡將會描述這些方法，以及何時可以使用它們。但注意，並不是所有方法都適用於所有訊息。

## Query String Serialization

此序列方法使用 `application/x-www-form-urlencoded` 對參數格式化，並放在 URI 的 query component。這方法基本上會使用在 HTTP `GET` 請求，另一種使用情況是用在 fragment component。

下面是一個簡單的範例（換行單純是為了可讀性）：

```
GET /authorize?
  response_type=code
  &scope=openid
  &client_id=s6BhdRkqt3
  &redirect_uri=https%3A%2F%2Fclient.example.org%2Fcb HTTP/1.1
Host: server.example.com
```

## Form Serialization

當使用 Form Serialization，會把參數和值使用 `application/x-www-form-urlencoded` 格式化，並放在 HTTP request 的 body 裡。基本上是使用在 HTTP `POST` 請求。

下面是一個簡單的範例（換行單純是為了可讀性）：

```
POST /authorize HTTP/1.1
Host: server.example.com
Content-Type: application/x-www-form-urlencoded

response_type=code
  &scope=openid
  &client_id=s6BhdRkqt3
  &redirect_uri=https%3A%2F%2Fclient.example.org%2Fcb
```

## JSON Serialization
