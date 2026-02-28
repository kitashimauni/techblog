+++
title = 'ブログ制作記 #7'
date = '2025-03-02T20:17:29+09:00'
lastmod = '2025-12-01T20:17:29+09:00'
draft = false
summary = 'Hugoでリンクカード、カスタムページネーションの実装とheadタグのメタ情報を整備をします'
tags = [ "Web", "Hugo" ]
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

作成したコードは以下です。
正規表現を用いて特定のタグの値を抜き出しています。

(1度 `partial` で実装してから `shortcode` で呼び出すようにしました。)

> [!TIP]
> 追記(2025-12-01): 画像URLがHTMLエスケープされる場合があるため、`htmlUnescape`関数を使うように修正しました。

```html {name="layouts/partials/linkcard.html"}
{{- $url := urls.Parse .url }}
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
    {{ with resources.Get "images/noimage.png" }}
      {{- $image = .RelPermalink }}
    {{ end }}
    {{- $found := findRESubmatch `og:image["\'].*?content=["\'](.*?)["\']` $content 1 }}
    {{- range $found }}
      {{- $image = index . 1 | htmlUnescape }}
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
  {{ if ne $image "" }}
    <div class="link-card__image">
      <img src="{{ $image }}" alt="サイトの画像">
    </div>
  {{ end }}
</a>
```

{{< details summary="CSS" >}}
CSSは以下のように定義しました。

```css
/* リンクカードの表示 */
.link-card {
  display: flex;
  align-items: center;
  border: 1px solid #ddd;
  border-radius: 8px;
  text-decoration: none;
  color: #333;
  overflow: hidden;
  height: 110px;
  margin: 16px 0;
  background: #fff; /* 背景色を明示（念のため） */
}

/* 画像を囲むdivの方にも設定を追加（重要） */
.link-card__image {
  flex-shrink: 0; /* 横幅が縮まないように固定 */
  height: 100%;   /* 高さをカードいっぱいに */
  margin: 0;      /* 余計なマージンを排除 */
  padding: 0;     /* 余計なパディングを排除 */
}

.link-card__image img {
  width: 100%;    /* 親divに合わせる */
  height: 100%;   /* 親divに合わせる */
  
  /* 【修正点1】隙間なく埋める設定に変更 */
  object-fit: cover; 
  
  /* 【修正点2】画像下の数ピクセルの隙間を消す */
  vertical-align: bottom; 
}

.link-card__content {
  display: flex;
  flex-direction: column;
  padding: 10px;
  flex-grow: 1;
  justify-content: center;
  height: 100%;
  
  /* コンテンツが溢れた時の対策 */
  min-width: 0; 
}

.link-card__content:hover {
  background: #eee;
}

.link-card__title {
  font-size: 16px;
  font-weight: bold;
  margin: 0 0 5px;
  display: -webkit-box;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
  -webkit-line-clamp: 1;
  line-clamp: 1;
}

.link-card__description {
  font-size: 14px;
  color: #555;
  margin: 0 0 8px;
  display: -webkit-box;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
  -webkit-line-clamp: 1;
  line-clamp: 1;
}

.link-card__url {
  font-size: 12px;
  margin: 5px 0;
  color: #555;
}
```

{{< /details >}}

`shortcode` 本体は以下のように作成します。

```html {name="layouts/shortcodes/linkcard.html"}
{{ partial "linkcard.html" (dict "url" .Get 0) }}
```

このshortcodeを使ってmdで以下のように書くことでリンクカードを埋め込むことができます。

```md
{{</* linkcard "https://www.youtube.com" */>}}
```

以下のように出力されます。

{{< linkcard "https://www.youtube.com" >}}

## ページネーション
現状では、記事の一覧では1つのページに全ての記事が表示されます。これを、10記事ごとに分割します。

まず、`hugo.toml`に以下を追記します。`pagerSize`は各ページに何記事表示するか、`path`はページネーションの際のパスです。

```toml {name="hugo.toml"}
[pagination]
  disableAliases = false
  pagerSize = 10
  path = 'list'
```

デフォルトのページネーション機能がありますが、今後調整する可能性があることを踏まえて、`layouts/partials/pagination.html`を新たに作成し、以下のコードをコピーします。

{{< linkcard "https://github.com/gohugoio/hugo/blob/master/tpl/tplimpl/embedded/templates/pagination.html" >}}

コピーしたコード上でcustomというフォーマットを使えるようにするため、defaultをコピーした以下のコードを追記します。わかりやすいようにクラス名を一部変更しています。

```html {name="layouts/partials/pagination.htmlのcustom部分"}
{{/* Format: custom  
{{/* --------------------------------------------------------------------- */}}
{{- define "partials/inline/pagination/custom" }}
  {{- with .Paginator }}
    {{- $currentPageNumber := .PageNumber }}

    {{- with .First }}
      {{- if ne $currentPageNumber .PageNumber }}
      <li class="pagination-item">
        <a href="{{ .URL }}" aria-label="First" class="pagination-page-link" role="button"><span aria-hidden="true">&laquo;&laquo;</span></a>
      </li>
      {{- else }}
      <li class="pagination-item disabled">
        <a aria-disabled="true" aria-label="First" class="pagination-page-link" role="button" tabindex="-1"><span aria-hidden="true">&laquo;&laquo;</span></a>
      </li>
      {{- end }}
    {{- end }}

    {{- with .Prev }}
      <li class="pagination-item">
        <a href="{{ .URL }}" aria-label="Previous" class="pagination-page-link" role="button"><span aria-hidden="true">&laquo;</span></a>
      </li>
    {{- else }}
      <li class="pagination-item disabled">
        <a aria-disabled="true" aria-label="Previous" class="pagination-page-link" role="button" tabindex="-1"><span aria-hidden="true">&laquo;</span></a>
      </li>
    {{- end }}

    {{- $slots := 5 }}
    {{- $start := math.Max 1 (sub .PageNumber (math.Floor (div $slots 2))) }}
    {{- $end := math.Min .TotalPages (sub (add $start $slots) 1) }}
    {{- if lt (add (sub $end $start) 1) $slots }}
      {{- $start = math.Max 1 (add (sub $end $slots) 1) }}
    {{- end }}

    {{- range $k := seq $start $end }}
      {{- if eq $.Paginator.PageNumber $k }}
      <li class="pagination-item active">
        <a aria-current="page" aria-label="Page {{ $k }}" class="pagination-page-link" role="button">{{ $k }}</a>
      </li>
      {{- else }}
      <li class="pagination-item">
        <a href="{{ (index $.Paginator.Pagers (sub $k 1)).URL }}" aria-label="Page {{ $k }}" class="pagination-page-link" role="button">{{ $k }}</a>
      </li>
      {{- end }}
    {{- end }}

    {{- with .Next }}
      <li class="pagination-item">
        <a href="{{ .URL }}" aria-label="Next" class="pagination-page-link" role="button"><span aria-hidden="true">&raquo;</span></a>
      </li>
    {{- else }}
      <li class="pagination-item disabled">
        <a aria-disabled="true" aria-label="Next" class="pagination-page-link" role="button" tabindex="-1"><span aria-hidden="true">&raquo;</span></a>
      </li>
    {{- end }}

    {{- with .Last }}
      {{- if ne $currentPageNumber .PageNumber }}
      <li class="pagination-item">
        <a href="{{ .URL }}" aria-label="Last" class="pagination-page-link" role="button"><span aria-hidden="true">&raquo;&raquo;</span></a>
      </li>
      {{- else }}
      <li class="pagination-item disabled">
        <a aria-disabled="true" aria-label="Last" class="pagination-page-link" role="button" tabindex="-1"><span aria-hidden="true">&raquo;&raquo;</span></a>
      </li>
      {{- end }}
    {{- end }}
  {{- end }}
{{- end -}}
```

さらに、 一番上のコードを以下のように変更し、customが使えるようにします。
```html {name="layouts/partials/pagination.html"}
{{- $validFormats := slice "default" "terse" "custom" }}
```

以下はコード全文です。defaultとの変更点はほとんどないので、組み込みのテンプレートでも十分かもしれません。

{{< details summary="コード全体" >}}
```html {name="layouts/partials/pagination.html"}
{{- $validFormats := slice "default" "terse" "custom" }}

{{- $msg1 := "When passing a map to the internal pagination template, one of the elements must be named 'page', and it must be set to the context of the current page." }}
{{- $msg2 := "The 'format' specified in the map passed to the internal pagination template is invalid. Valid choices are: %s." }}

{{- $page := . }}
{{- $format := "default" }}

{{- if reflect.IsMap . }}
  {{- with .page }}
    {{- $page = . }}
  {{- else }}
    {{- errorf $msg1 }}
  {{- end }}
  {{- with .format }}
    {{- $format = lower . }}
  {{- end }}
{{- end }}

{{- if in $validFormats $format }}
  {{- if gt $page.Paginator.TotalPages 1 }}
    <ul class="pagination pagination-{{ $format }}">
      {{- partial (printf "partials/inline/pagination/%s" $format) $page }}
    </ul>
  {{- end }}
{{- else }}
  {{- errorf $msg2 (delimit $validFormats ", ") }}
{{- end -}}

{{/* Format: custom  
{{/* --------------------------------------------------------------------- */}}
{{- define "partials/inline/pagination/custom" }}
  {{- with .Paginator }}
    {{- $currentPageNumber := .PageNumber }}

    {{- with .First }}
      {{- if ne $currentPageNumber .PageNumber }}
      <li class="pagination-item">
        <a href="{{ .URL }}" aria-label="First" class="pagination-page-link" role="button"><span aria-hidden="true">&laquo;&laquo;</span></a>
      </li>
      {{- else }}
      <li class="pagination-item disabled">
        <a aria-disabled="true" aria-label="First" class="pagination-page-link" role="button" tabindex="-1"><span aria-hidden="true">&laquo;&laquo;</span></a>
      </li>
      {{- end }}
    {{- end }}

    {{- with .Prev }}
      <li class="pagination-item">
        <a href="{{ .URL }}" aria-label="Previous" class="pagination-page-link" role="button"><span aria-hidden="true">&laquo;</span></a>
      </li>
    {{- else }}
      <li class="pagination-item disabled">
        <a aria-disabled="true" aria-label="Previous" class="pagination-page-link" role="button" tabindex="-1"><span aria-hidden="true">&laquo;</span></a>
      </li>
    {{- end }}

    {{- $slots := 5 }}
    {{- $start := math.Max 1 (sub .PageNumber (math.Floor (div $slots 2))) }}
    {{- $end := math.Min .TotalPages (sub (add $start $slots) 1) }}
    {{- if lt (add (sub $end $start) 1) $slots }}
      {{- $start = math.Max 1 (add (sub $end $slots) 1) }}
    {{- end }}

    {{- range $k := seq $start $end }}
      {{- if eq $.Paginator.PageNumber $k }}
      <li class="pagination-item active">
        <a aria-current="page" aria-label="Page {{ $k }}" class="pagination-page-link" role="button">{{ $k }}</a>
      </li>
      {{- else }}
      <li class="pagination-item">
        <a href="{{ (index $.Paginator.Pagers (sub $k 1)).URL }}" aria-label="Page {{ $k }}" class="pagination-page-link" role="button">{{ $k }}</a>
      </li>
      {{- end }}
    {{- end }}

    {{- with .Next }}
      <li class="pagination-item">
        <a href="{{ .URL }}" aria-label="Next" class="pagination-page-link" role="button"><span aria-hidden="true">&raquo;</span></a>
      </li>
    {{- else }}
      <li class="pagination-item disabled">
        <a aria-disabled="true" aria-label="Next" class="pagination-page-link" role="button" tabindex="-1"><span aria-hidden="true">&raquo;</span></a>
      </li>
    {{- end }}

    {{- with .Last }}
      {{- if ne $currentPageNumber .PageNumber }}
      <li class="pagination-item">
        <a href="{{ .URL }}" aria-label="Last" class="pagination-page-link" role="button"><span aria-hidden="true">&raquo;&raquo;</span></a>
      </li>
      {{- else }}
      <li class="pagination-item disabled">
        <a aria-disabled="true" aria-label="Last" class="pagination-page-link" role="button" tabindex="-1"><span aria-hidden="true">&raquo;&raquo;</span></a>
      </li>
      {{- end }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/* Format: default
{{/* --------------------------------------------------------------------- */}}
{{- define "partials/inline/pagination/default" }}
  {{- with .Paginator }}
    {{- $currentPageNumber := .PageNumber }}

    {{- with .First }}
      {{- if ne $currentPageNumber .PageNumber }}
      <li class="page-item">
        <a href="{{ .URL }}" aria-label="First" class="page-link" role="button"><span aria-hidden="true">&laquo;&laquo;</span></a>
      </li>
      {{- else }}
      <li class="page-item disabled">
        <a aria-disabled="true" aria-label="First" class="page-link" role="button" tabindex="-1"><span aria-hidden="true">&laquo;&laquo;</span></a>
      </li>
      {{- end }}
    {{- end }}

    {{- with .Prev }}
      <li class="page-item">
        <a href="{{ .URL }}" aria-label="Previous" class="page-link" role="button"><span aria-hidden="true">&laquo;</span></a>
      </li>
    {{- else }}
      <li class="page-item disabled">
        <a aria-disabled="true" aria-label="Previous" class="page-link" role="button" tabindex="-1"><span aria-hidden="true">&laquo;</span></a>
      </li>
    {{- end }}

    {{- $slots := 5 }}
    {{- $start := math.Max 1 (sub .PageNumber (math.Floor (div $slots 2))) }}
    {{- $end := math.Min .TotalPages (sub (add $start $slots) 1) }}
    {{- if lt (add (sub $end $start) 1) $slots }}
      {{- $start = math.Max 1 (add (sub $end $slots) 1) }}
    {{- end }}

    {{- range $k := seq $start $end }}
      {{- if eq $.Paginator.PageNumber $k }}
      <li class="page-item active">
        <a aria-current="page" aria-label="Page {{ $k }}" class="page-link" role="button">{{ $k }}</a>
      </li>
      {{- else }}
      <li class="page-item">
        <a href="{{ (index $.Paginator.Pagers (sub $k 1)).URL }}" aria-label="Page {{ $k }}" class="page-link" role="button">{{ $k }}</a>
      </li>
      {{- end }}
    {{- end }}

    {{- with .Next }}
      <li class="page-item">
        <a href="{{ .URL }}" aria-label="Next" class="page-link" role="button"><span aria-hidden="true">&raquo;</span></a>
      </li>
    {{- else }}
      <li class="page-item disabled">
        <a aria-disabled="true" aria-label="Next" class="page-link" role="button" tabindex="-1"><span aria-hidden="true">&raquo;</span></a>
      </li>
    {{- end }}

    {{- with .Last }}
      {{- if ne $currentPageNumber .PageNumber }}
      <li class="page-item">
        <a href="{{ .URL }}" aria-label="Last" class="page-link" role="button"><span aria-hidden="true">&raquo;&raquo;</span></a>
      </li>
      {{- else }}
      <li class="page-item disabled">
        <a aria-disabled="true" aria-label="Last" class="page-link" role="button" tabindex="-1"><span aria-hidden="true">&raquo;&raquo;</span></a>
      </li>
      {{- end }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/* Format: terse
{{/* --------------------------------------------------------------------- */}}
{{- define "partials/inline/pagination/terse" }}
  {{- with .Paginator }}
    {{- $currentPageNumber := .PageNumber }}

    {{- with .First }}
      {{- if ne $currentPageNumber .PageNumber }}
      <li class="page-item">
        <a href="{{ .URL }}" aria-label="First" class="page-link" role="button"><span aria-hidden="true">&laquo;&laquo;</span></a>
      </li>
      {{- end }}
    {{- end }}

    {{- with .Prev }}
      <li class="page-item">
        <a href="{{ .URL }}" aria-label="Previous" class="page-link" role="button"><span aria-hidden="true">&laquo;</span></a>
      </li>
    {{- end }}

    {{- $slots := 3 }}
    {{- $start := math.Max 1 (sub .PageNumber (math.Floor (div $slots 2))) }}
    {{- $end := math.Min .TotalPages (sub (add $start $slots) 1) }}
    {{- if lt (add (sub $end $start) 1) $slots }}
      {{- $start = math.Max 1 (add (sub $end $slots) 1) }}
    {{- end }}

    {{- range $k := seq $start $end }}
      {{- if eq $.Paginator.PageNumber $k }}
      <li class="page-item active">
        <a aria-current="page" aria-label="Page {{ $k }}" class="page-link" role="button">{{ $k }}</a>
      </li>
      {{- else }}
      <li class="page-item">
        <a href="{{ (index $.Paginator.Pagers (sub $k 1)).URL }}" aria-label="Page {{ $k }}" class="page-link" role="button">{{ $k }}</a>
      </li>
      {{- end }}
    {{- end }}

    {{- with .Next }}
      <li class="page-item">
        <a href="{{ .URL }}" aria-label="Next" class="page-link" role="button"><span aria-hidden="true">&raquo;</span></a>
      </li>
    {{- end }}

    {{- with .Last }}
      {{- if ne $currentPageNumber .PageNumber }}
      <li class="page-item">
        <a href="{{ .URL }}" aria-label="Last" class="page-link" role="button"><span aria-hidden="true">&raquo;&raquo;</span></a>
      </li>
      {{- end }}
    {{- end }}
  {{- end }}
{{- end -}}
```
{{< /details >}}

CSSで見た目を整えます。HTMLをいじらずにCSSを書くだけで十分だったかもしれません。

```css {name="assets/css/main.css"}
/* ページネーション */
.pagination-custom {
  display: flex;
  list-style: none;
  padding: 0;
  margin: 20px 0;
  justify-content: center;
  align-items: center;
  gap: 5px;
}

.pagination-item {
  display: inline-block;
}

.pagination-page-link {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  padding: 5px;
  text-decoration: none;
  color: #333;
  font-size: 16px;
  font-weight: bold;
  background-color: #fff;
  border: 1px solid #ccc;
  border-radius: 5px;
}

.pagination-item.active .pagination-page-link {
  background-color: #007bff;
  color: #fff;
  border-color: #007bff;
  pointer-events: none;
}

.pagination-item.disabled .pagination-page-link {
  color: #aaa;
  background-color: #f5f5f5;
  border-color: #ddd;
  pointer-events: none;
  cursor: default;
}
```

最後に記事一覧の表示部分である`layouts/_default/list.html`を以下のようにして完了です。

```html {name=""}
{{ define "main" }}
  <h1>{{ .Title }}</h1>
  {{ .Content }}

  {{ $paginator := .Paginate .Pages }}

  {{ partial "pagelist.html" (dict "pages" $paginator.Pages) }}

  {{ partial "pagination.html" (dict "page" . "format" "custom") }}
{{ end }}
```

出来上がりはこのような感じです。かなりいい感じだと思います。

{{< figure src="/src/pagination.png" alt="完成したpagination" >}}

## headを整備する
リンクカードの実装時にOGPタグから情報を得ていましたが、このサイトのheadタグ内はデフォルトのままだったのでmetaタグなどがほとんどありません。

head内の情報を増やします。`layouts/partials/head.html`に追記して以下のようにしました。

アイコン画像はまだないので保留です。

```html {{name="layouts/partials/head.html"}}
{{- $title := "" }}
{{ if .IsHome }}
  {{ $title = site.Title }}
{{ else }}
  {{ $title = printf "%s | %s" .Title site.Title }}
{{ end }}

<meta charset="utf-8">
<meta name="viewport" content="width=device-width">
<meta http-equiv="X-UA-Compatible" content="IE=edge">

<meta name="description" content="{{ .Summary }}">
<meta name="robots" content="index, follow">  <!-- クローラーにページをインデックスさせる -->
{{ with .GitInfo }}
  <meta name="author" content="{{ .AuthorName }}">  <!-- 作成者情報 -->
{{- end }}
<meta name="generator" content="Hugo">  <!-- 生成ツール -->

<meta property="og:title" content="{{ $title }}">
<meta property="og:description" content="{{ .Summary }}">
<!-- <meta property="og:image" content="https://example.com/image.jpg"> --> <!-- TODO: アイコン画像の追加  -->
<meta property="og:url" content="{{ urls.JoinPath site.BaseURL .RelPermalink }}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="{{ site.Title }}">

<meta name="twitter:card" content="summary">
<meta name="twitter:title" content="{{ $title }}">
<meta name="twitter:description" content="{{ .Summary }}">
<!-- <meta name="twitter:image" content="https://example.com/image.jpg"> --> <!-- TODO: アイコン画像の追加 -->
<!-- <meta name="twitter:site" content="@Twitterアカウント"> --> <!-- のちほど追加するかも -->



<title>{{ $title }}</title>
{{ partialCached "head/css.html" . }}
{{ partialCached "head/js.html" . }}
```

## おわりに
欲しい機能が追加できました。少し難易度は高そうですが、検索機能も付けてみたいです。