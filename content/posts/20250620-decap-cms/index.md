---
title: Decap CMSで
url_title: decap-cms
date: 2025-06-20T14:51:00.000Z
draft: false
tags:
  - Hugo
  - Decap CMS
---
Hugoで記事を書いているとCMSが欲しくなってきました。

この記事では、Decap CMSとSveltia CMSのOAuth Clientを使ってHugoの記事を書けるCMSを整備したので、その過程を記します。

せっかく自宅サーバーがあるのでそれを使えたらと思ったのですが、今回の構成ではCloudflareだけで完結しました。

## 技術選定
元々、GitHub上でHugoの本体と記事を管理していました。

そこで、GitHub上に記事を置きつつ、それを簡単に扱うことができるヘッドレスCMSを探しました。

見つけたのは以下のようなCMSです。

- Netlify CMS
- Decap CMS(Netlify CMSの代替)
- Sveltia CMS(Decap/Netlify CMSの代替)

この中ではSveltia CMSがモバイルでの編集も快適にできてよさそうだったのですが、mainに直接pushせずにドラフト版として置いておくことのできる
