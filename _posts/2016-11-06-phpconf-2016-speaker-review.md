---
layout: post
title: PHPConf 2016 講者心得
---

其實，一開始投稿是寫「框架組合技之 Slim 篇」的。

<img width="400" src="/images/phpconf2016.jpg" />

本來想說要講單純的 Slim 可以自由搭配其他套件做出自定義框架（後來才發現有前輩有講過類似的：[蒼時弦也 - Framework or Framework Less](https://docs.google.com/file/d/0B-59_4gDCY8XUENJVmdBV0dqbE0)）。後來議程組在9月初時，建議我把主題改成 Slim 應用，因為 Slim 之父 Josh 會來，主軸放在 Slim 上會比較好。想想也對，剛好那陣子在看 Microservice 有翻到 Nginx Blog 裡提到[如何把 Monolith 重構成 Microservices](https://www.nginx.com/blog/refactoring-a-monolith-into-microservices/)，也就是簡報概念一開始提到的參考資料，於是就靈機一動，主題換成「使用 Slim 為 Legacy Code 重構」。

簡報的開頭故事是從我親身體驗改編。事實上，這主題與簡介裡也帶著我蠻多個人的怨念。我是那種看到程式能改得更好，就會手賤想去改的人，但 legacy code 都沒有測試，所以很容易把系統整個改壞，最後就會被要求不能再亂動程式。

為了想去改這個程式，去學了測試和建環境的方法。DevOps 給我最大的啟發是，產品是公司的，因此身為公司的任何人都能為這個產品做任何努力。我知道維運人員想要穩定，老闆想要功能，重構的方法如果能把大家的想法都考慮進去的話，勢必會有不一樣的結果。最後，想出這個方法，它對維運的影響不大，而且能同時開發與重構。這是目前我能想得到的最好方法了。

參考文獻和重構方法都準備好後，我還需要克服自己的心理障礙。以前每當遇到要 present 時，都會覺得很恐懼。前公司的同事，在我 present 時的氣氛都很自然，所以以前常常會主動 present 一些技術。這次時空場景不大一樣了，場面變大，不認識的人變多，說我不會怕是騙人的，當然非常緊張害怕。

前幾個禮拜跟朋友聊這件事，他只跟我說「主辦單位都不怕了，你有什麼好怕的？」，好像蠻有道理的耶！加上 Josh 當天提到怎麼當一個更好的開發者時，有提到：「Share your knowledge」，更覺得心情放鬆了點。記得我是到 Q & A 快結束的時候才發現，好多人。講的時候都專注在分享上，也沒注意原來這麼多人。順帶一提，Q & A 個人覺得回答算很順暢，現在回想起來也是很意外自己也能做到這樣。

簡單形容這次當講者的感覺，我想主要是「緊張刺激」吧！上台前的緊張，台上的刺激。另外就是下台後的感謝。例行性的都要感謝一下家人、工作人員和謝天等等。特別提一下，我最想感謝的是議程組，如果沒有他們的認可，就不用在那邊緊張老半天，但同時也不會有這篇文章了。而且，經歷過這場演講，我覺得我的表達能力有前進小小一步，這也算是議程組間接推我前進的，非常感謝議程組。

之後還會不會報名講者？有合適的主題，同時主辦單位也接受的話，我想我會再去吧！就像 Josh 說的：

> Share your knowledge

## References

* [Facebook](https://www.facebook.com/notes/miles-chou/20161029-phpconf-2016-%E8%AC%9B%E8%80%85%E5%BF%83%E5%BE%97/10155499087044741)
