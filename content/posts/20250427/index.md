+++
title = 'ブログ制作記 #11'
date = '2025-04-27T23:14:39+09:00'
draft = true
summary = 'ブログ制作記 第11回'
tags = ['Hugo', 'Web']
+++

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
Hugoについて調べていたとき、`site.RegularPages.Related`なるものがあるのを見つけました。どうやら関連記事を簡単に取得できるようです。

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

```toml {name="hugo.toml"}
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

## おわりに

