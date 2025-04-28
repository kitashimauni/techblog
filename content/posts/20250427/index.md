+++
title = 'ブログ制作記 #11'
date = '2025-04-27T23:14:39+09:00'
draft = false
summary = 'ブログ制作記 第11回'
tags = ['Hugo', 'Web']
+++
引き続き、記事を書いていて欲しくなった機能を追加していきます。

## 装飾
### リンクの装飾
記事中のリンクはデフォルトのままなので少しだけ装飾します。

```css {name="assets/css/main.css"}
/* リンク */
.content_container p > a {
  color: #0077cc;
  text-decoration: underline;
  font-weight: bold;
  transition: color 0.3s ease, text-decoration-color 0.3s ease;
}

.content_container p > a:hover {
  color: #005fa3;
  text-decoration-color: #005fa3;
}
```

### detailsの装飾
shortcodeで`details`を使うと装飾がなくてさみしいので`details`も装飾します。

```css {name="assets/css/main.css"}
/* details全体にスタイルを当てる */
.content_container details {
  margin: 1em 0;
  padding: 0.5em 1em;
  border: 1px solid #cddfea;
  border-radius: 0.5em;
  background-color: #f9fcff;
  transition: background-color 0.3s ease;
  overflow: hidden;
}

/* summary部分 */
.content_container summary {
  cursor: pointer;
  font-weight: bold;
  color: #336699;
  padding: 0.5em 0;
  list-style: none; /* デフォルトの▶を消す場合 */
  position: relative;
}

/* summaryのhover */
.content_container summary:hover {
  color: #224466;
}

/* ▶マークを自作する */
.content_container summary::before {
  content: "▶";
  top: 50%;
  padding-right: 5pt;
  transform: translateY(-50%);
  font-size: 0.8em;
  transition: transform 0.2s ease;
}

/* detailsが開いたときのマークを変える */
.content_container details[open] summary::before {
  content: "▼";
}

/* detailsが開いた時、背景を少し濃くする */
.content_container details[open] {
  background-color: #eef6fb;
}
```

## 関連記事の表示
HUGOについて調べていたとき、`site.RegularPages.Related`なるものがあるのを見つけました。どうやら関連記事を簡単に取得できるようです。

{{< linkcard "https://gohugo.io/content-management/related-content/" >}}

`layouts/_default/single.html`を以下のように書き換えます。コンテンツの下部に関連記事を表示する部分を作りました。

```html {name="layouts/_default/single.html"}
{{ define "main" }}
  <div class="title_container">
    <h1>{{ .Title }}</h1>
  </div>

  <div class="meta_container">
    {{ $dateMachine := .Date | time.Format "2006-01-02T15:04:05-07:00" }}
    {{ $dateHuman := .Date | time.Format "2006/01/02" }}
    <div>投稿日
      <time datetime="{{ $dateMachine }}">{{ $dateHuman }}</time>
      {{ if ne .Lastmod .Date }}
        {{ $updateDate := .Lastmod | time.Format "2006/01/02" }}
        <br>
        (最終更新:<time datetime="{{ $dateMachine }}">{{ $updateDate }}</time>)
      {{ end }}
      <br>
      {{ partial "terms.html" (dict "taxonomy" "tags" "page" .) }}
    </div>
  </div>
  
  <div class="content_container">
    {{ .Content }}
  </div>

  {{ with site.RegularPages.Related . | first 6 }}
    <hr class="section-divider">
    {{ if ne .Len 0 }}
      <div class="related_posts_container">
        <div class="related-articles">
          <h2>関連記事</h2>
        </div>
        {{ partial "pagelist.html" (dict "pages" .) }}
      </div>
    {{ end }}
  {{ end }}
{{ end }}
```

{{< details summary="CSS" >}}
```css {name="assets/css/main.css"}
.related-articles h2 {
  display: inline-block;
  font-size: 1.2em;
  background-color: #eef6fb;
  color: #336699;
  padding: 0.3em 0.8em;
  border-radius: 9999px;
  margin-bottom: 1em;
}
```
{{< /details >}}

また、プロジェクト直下の`hugo.toml`に以下を追記します。デフォルトとさして変わりませんが、より新しい記事も関連記事に含まれるように変更しています。

```toml {name="hugo.toml (追記)"}
[related]
  includeNewer = true
  threshold = 80
  toLower = false
  [[related.indices]]
    applyFilter = false
    cardinalityThreshold = 0
    name = 'keywords'
    pattern = ''
    toLower = false
    type = 'basic'
    weight = 100
  [[related.indices]]
    applyFilter = false
    cardinalityThreshold = 0
    name = 'date'
    pattern = ''
    toLower = false
    type = 'basic'
    weight = 10
  [[related.indices]]
    applyFilter = false
    cardinalityThreshold = 0
    name = 'tags'
    pattern = ''
    toLower = false
    type = 'basic'
    weight = 80
```

## minifyを設定する
現状ではHTMLやJS、CSSの最小化は行われておらず、以下のように無駄な改行などが目立ちます。これを解消するため、minifyの設定をします。

```html {name="無駄な改行が目立つhtmlの出力 (一部)"}
!DOCTYPE html>
<html lang="ja-jp" dir="ltr">
<head><script src="/livereload.js?mindelay=10&amp;v=2&amp;port=1313&amp;path=livereload" data-no-instant defer></script>
  

  


<meta charset="utf-8">
<meta name="viewport" content="width=device-width">
<meta http-equiv="X-UA-Compatible" content="IE=edge">

<meta name="description" content="初投稿記事です">
```

プロジェクト直下の`hugo.toml`に以下を追記します。デフォルトを貼り付けたうえで`minifyOutput = true`としました。これで対応しているファイルは全てminifyされます。

```toml {name="hugo.toml (追記)"}
[minify]
  disableCSS = false
  disableHTML = false
  disableJS = false
  disableJSON = false
  disableSVG = false
  disableXML = false
  minifyOutput = true
  [minify.tdewolff]
    [minify.tdewolff.css]
      inline = false
      keepCSS2 = true
      precision = 0
    [minify.tdewolff.html]
      keepComments = false
      keepConditionalComments = false
      keepDefaultAttrVals = true
      keepDocumentTags = true
      keepEndTags = true
      keepQuotes = false
      keepSpecialComments = true
      keepWhitespace = false
      templateDelims = ['', '']
    [minify.tdewolff.js]
      keepVarNames = false
      precision = 0
      version = 0
    [minify.tdewolff.json]
      keepNumbers = false
      precision = 0
    [minify.tdewolff.svg]
      inline = false
      keepComments = false
      precision = 0
    [minify.tdewolff.xml]
      keepWhitespace = false
```

minifyを設定した後、改行の目立っていたhtmlは次のようになりました。改行のほとんどが削除され、一行に詰め込まれていることがわかります。

```html {name="minify後のhtml (一部)"}
<!doctype html><html lang=ja-jp dir=ltr><head><script src="/livereload.js?mindelay=10&amp;v=2&amp;port=1313&amp;path=livereload" data-no-instant defer></script><meta charset=utf-8><meta name=viewport content="width=device-width"><meta http-equiv=X-UA-Compatible content="IE=edge"><meta name=description content="初投稿記事です"><meta name=robots content="index, follow"><meta name=generator content="Hugo"><meta property="og:title" content="初投稿 | テック島開拓記"><meta property="og:description" content="初投稿記事です"><meta property="og:image" content="/images/title.png"><meta property="og:url" content="http://localhost:1313/posts/20250204-1/"><meta property="og:type" content="website"><meta property="og:site_name" content="テック島開拓記"><meta name=twitter:card content="summary"><meta name=twitter:title content="初投稿 | テック島開拓記"><meta name=twitter:description content="初投稿記事です"><meta name=twitter:image content="/images/title.png"><title>初投稿 | テック島開拓記</title>
```

minifyについては`--minify`オプションを付けることでも有効化できるようです。

## 画像をwebpへ変換
現状では画像に対して何も処理しておらず、記事中ではpng画像が多いです。しかし、png画像はサイズが大きくなりがちで100KBを超えるものもあります。

HUGOでは`RESOURCE.Resize`というメソッドが提供されており、これによってフォーマットの変換が可能です。

{{< linkcard "https://gohugo.io/methods/resource/resize" >}}

今回は記事中の画像埋め込みに使用しているビルトインのshortcodeである`figure`に変更を加えます。

以下からコードを取得し、以下のように書き換えます。

{{< linkcard "https://github.com/gohugoio/hugo/blob/master/tpl/tplimpl/embedded/templates/_shortcodes/figure.html" >}}

```html {name="layouts/shortcodes/figure.html" hl_lines=["10-12"]}
<figure{{ with .Get "class" }} class="{{ . }}"{{ end }}>
  {{- if .Get "link" -}}
    <a href="{{ .Get "link" }}"{{ with .Get "target" }} target="{{ . }}"{{ end }}{{ with .Get "rel" }} rel="{{ . }}"{{ end }}>
  {{- end -}}

  {{- $u := urls.Parse (.Get "src") -}}
  {{- $src := $u.String -}}
  {{- if not $u.IsAbs -}}
    {{- with or (.Page.Resources.Get $u.Path) (resources.Get $u.Path) -}}
      {{- with .Resize (printf "%dx%d webp" .Width .Height) -}}
        {{- $src = .RelPermalink -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  <img src="{{ $src }}"
    {{- if or (.Get "alt") (.Get "caption") }}
    alt="{{ with .Get "alt" }}{{ . }}{{ else }}{{ .Get "caption" | markdownify| plainify }}{{ end }}"
    {{- end -}}
    {{- with .Get "width" }} width="{{ . }}"{{ end -}}
    {{- with .Get "height" }} height="{{ . }}"{{ end -}}
    {{- with .Get "loading" }} loading="{{ . }}"{{ end -}}
  ><!-- Closing img tag -->
  {{- if .Get "link" }}</a>{{ end -}}
  {{- if or (or (.Get "title") (.Get "caption")) (.Get "attr") -}}
    <figcaption>
      {{ with (.Get "title") -}}
        <h4>{{ . }}</h4>
      {{- end -}}
      {{- if or (.Get "caption") (.Get "attr") -}}<p>
        {{- .Get "caption" | markdownify -}}
        {{- with .Get "attrlink" }}
          <a href="{{ . }}">
        {{- end -}}
        {{- .Get "attr" | markdownify -}}
        {{- if .Get "attrlink" }}</a>{{ end }}</p>
      {{- end }}
    </figcaption>
  {{- end }}
</figure>
```

これでshortcode`figure`を用いて表示される画像はwebpに変換されるようになりました。

## おわりに
関連記事の実装については、クローラが巡回しやすくなるようにするという若干のSEO対策要素があります。「テック島開拓記」でGoogle検索しても全く出てこないのが困りどころです。

また、以前から検討していた検索機能については、全文検索の実装自体は可能なものの、クライアント側だけで完結する実装は処理速度的に厳しいという結論に至ったため後回しにします。

今後も欲しくなった機能を追加していきます。デザインも方向性を定めたいです。
