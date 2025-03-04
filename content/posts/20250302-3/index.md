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
- サイト画像 (og:image, 最初のimgタグのsrc)
- 説明 (og:description, metaタグのname=description)
- サイトURL (与えられたURL)

作成したコードは以下です。長いので畳み込んであります。
正規表現を用いて特定のタグの値を抜き出しています。

{{< details summary="作成したhtml" >}}
```html {name="layouts/shortcodes/linkcard.html"}
{{- $url := urls.Parse (.Get 0) }}
{{- $title := "" }}
{{- $description := "" }}
{{- $image := "" }}
{{- $siteURL := "" }}
{{- with try (resources.GetRemote $url) }}
  {{ with .Err }} <!-- Error occurred while fetching remote -->
    {{- warnf "%s" . }}
    {{- $title = "Error occurred while fetching remote" }}
    {{- $siteURL = $url.Hostname }}
  {{ else with .Value }} <!-- get OGP remote resource -->
    {{- $content := .Content }}
    <!-- get title -->
    {{- $found := findRESubmatch `og:title["\'].*?content=["\'](.*?)["\']` $content 1 }}
    {{- range $found }}
      {{- $title = index . 1 }}
    {{- end }}
    {{- if eq $title "" }}
      {{- $found := findRESubmatch `<title>(.*?)</title>` $content 1 }}
      {{- range $found }}
        {{- $title = index . 1 }}
      {{- end }}
    {{- end }}

    <!-- get description -->
    {{- $found := findRESubmatch `og:description["\'].*?content=["\'](.*?)["\']` $content 1 }}
    {{- range $found }}
      {{- $description = index . 1 }}
    {{- end }}
    {{- if eq $description "" }}
      {{- $found := findRESubmatch `description["\'].*?content=["\''](.*?)["\']` $content 1 }}
      {{- range $found }}
        {{- $description = index . 1 }}
      {{- end }}
    {{- end }}

    <!-- get image -->
    {{- $found := findRESubmatch `og:image["\'].*?content=["\'](.*?)["\']` $content 1 }}
    {{- range $found }}
      {{- $image = index . 1 }}
    {{- end }}
    {{- if eq $image "" }}
      {{- $found := findRESubmatch `<img.*?src=["\'](.*?)["\']` $content 1 }}
      {{- range $found }}
        {{- $image = index . 1 }}
      {{- end }}
      {{- if eq (slicestr $image 0 1) "/" }}
        {{- $host := urls.JoinPath "https://" $url.Hostname }}
        {{- $image =  urls.JoinPath $host $image }}
      {{- end }}
    {{- end }}

    <!-- get siteURL -->
    {{- $siteURL = $url.Hostname }}

  {{ else }} <!-- 404 -->
    {{ warnf "Unable to get remote resource %q" $url }}
    {{ $title = "Unable to get remote resource" }}
    {{ $siteURL = $url.Hostname }}
  {{ end }}
{{ end }}

<a href="{{ $url }}" target="_blank" class="link-card">
  <div class="link-card__content">
    <p class="link-card__title">{{ $title }}</p>
    <p class="link-card__description">{{ $description }}</p>
    <p class="link-card__url">{{ $siteURL }}</p>
  </div>
  <div class="link-card__image">
    <img src="{{ $image }}" alt="サイトの画像">
  </div>
</a>
```
{{< /details>}}

このshortcodeを使ってmdで以下のように書くことでリンクカードを埋め込むことができます。

```md
{{</* linkcard "https://www.youtube.com" */>}}
```

以下のように出力されます。

{{< linkcard "https://www.youtube.com" >}}
