+++
title = 'ブログ制作記 #7'
date = '2025-03-02T20:17:29+09:00'
draft = true
summary = 'ブログ制作記 第7回'
tags = ['Web', 'Hugo']
+++

ブログを書いていて欲しくなった機能を追加していきます。

## リンクカード
QiitaやZennなどでは、リンクを書き込むといい感じにリンクカードを表示してくれます。

記事を書いていると、公式ドキュメントなどのリンクを貼ることが多いのでリンクカードが欲しいです。

Hugoには[GetRemote](https://gohugo.io/functions/resources/getremote/)という関数があり、これを使うことで外部のURLからhtmlを取得できます。これを使うとリンクカードを生成するshortcodeを作ることができます。

`layouts/shortcodes`に`linkcard.html`を作ります。

リンクカードに載せたい情報は以下の4つです。

- タイトル
- サイト画像
- 説明
- サイトURL

OGPが設定されたサイトであれば、タイトル・サイト画像・説明はそれぞれmetaタグの`og:title`・`og:image`・`og:description`から取得できます。

ただし、全てのウェブサイトにOGPが設定されているとは限らないため、以下のカッコ内の順序に従って情報を得ます。

- タイトル (og:title, titleタグ)
- サイト画像 (og:image, 最初のimgタグ)
- 説明 (og:description, metaタグのname=description)
- サイトURL (与えられたURL)



{{< linkcard "https://www.youtube.com" >}}
