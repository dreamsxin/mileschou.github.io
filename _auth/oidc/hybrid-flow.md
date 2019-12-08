---
title: Hybrid Flow
layout: collections
---

流程描述如下：

1.  Client 準備帶有必要參數的驗證請求（Authentication Request）
2.  Client 將驗證請求發送給 Authorization Server
3.  Authorization Server 驗證 End-User 身份
4.  Authorization Server 取得 End-User 授權
5.  Authorization Server 將授權碼（Authorization Code）透過 End-User 送回給 Client，並且依據 response type 不同，會有數個額外的參數
6.  Client 使用授權碼向 Authorization Server 的 token endpoint 發送請求
7.  Client 收到代表 End-User 身份的 ID Token 跟 Access Token
8.  Client 驗證 ID Token 並取出使用者資訊
