---
title: Implicit Flow
layout: collections
---

流程描述如下：

1.  Client 準備帶有必要參數的驗證請求（Authentication Request）
2.  Client 將驗證請求發送給 Authorization Server
3.  Authorization Server 驗證 End-User 身份
4.  Authorization Server 取得 End-User 授權
5.  Authorization Server 將 ID Token 透過 End-User 送回給 Client，如果有額外要求的話，會再附加 Access Token
6.  Client 驗證 ID Token 並取出使用者資訊
