---
title: 專用術語
layout: collections
---

OpenID Connect 文件開頭有個[區塊](https://openid.net/specs/openid-connect-core-1_0.html#Terminology)即有先說明專用術語

## End-User

真實的使用者。

有的文件會簡稱 *EU*。

## Entity

> Something that has a separate and distinct existence and that can be identified in a context. An End-User is one example of an Entity.

場景中，獨立存在且可被識別的某個東西。End-User 即是一個例子。

## OpenID Provide（OP）

> OAuth 2.0 Authorization Server that is capable of Authenticating the End-User and providing Claims to a Relying Party about the Authentication event and the End-User.

需注意有的文件會直接簡稱為 *OP*。

## Relying Party（RP）

> OAuth 2.0 Client application requiring End-User Authentication and Claims from an OpenID Provider.

這裡指的是 OAuth 2.0 術語所稱的 *Client*，在 OpenID Connect 的流程裡，剛好有跟身分驗證的角色重疊，而身分驗證的術語是使用 *Relying Party*。

在 OpenID Connect 的世界裡，這兩個名詞指的是一樣的角色。

需注意有的文件會直接簡稱為 *RP*。
