+++
title = 'ブログ制作記 #10'
date = '2025-04-20T00:27:08+09:00'
draft = false
summary = 'ブログ制作記 第10回'
tags = ['Hugo', 'Web']
+++

記事を書いていて欲しくなった機能などを追加・修正していきます。

## linkcardで画像を取得できないときのデフォルト画像を用意する
現状だと`og:image`の画像か一番最初の画像を表示するようにしていますが、表示すべき画像がなかったり、一番最初の画像を表示しようしたりすると以下のようになってしまいます。

{{< figure src="src/no_image.png" alt="画像がないときの表示" >}}

これを解消するため、デフォルト画像を用意して表示する画像(`og:image`)が無いときはそれを表示するようにしました。

`assets/images`に「NO IMAGE」の画像を配置したうえで、`linkcard`のshortcodeを以下のように書き換えます。

```html {name="layouts/shortcodes/linkcard.html (画像取得部分)"}
<!-- get image -->
{{ with resources.Get "images/noimage.png" }}
    {{- $image = .RelPermalink }}
{{ end }}
{{- $found := findRESubmatch `og:image["\'].*?content=["\'](.*?)["\']` $content 1 }}
{{- range $found }}
    {{- $image = index . 1 }}
{{- end }}
```

これで画像がないときは以下のように「NO IMAGE」と表示されるようになりました。

{{< figure src="src/no_image_after.png" alt="画像がないときの表示(変更後)" >}}

## OGPタグに画像を指定する
タイトル画像ができたのでこれをOGPタグやTwitterタグに指定します。

以下を`layouts/partials/head.html`に追記します。

```html {name="layouts/partials/head.html (追記)"}
{{- with resources.Get (.Site.Param "titleImagePath") }}
  <meta property="og:image" content="{{ .RelPermalink }}">
{{- end }}

{{- with resources.Get (.Site.Param "titleImagePath") }}
  <meta name="twitter:image" content="{{ .RelPermalink }}">
{{- end }}
```

## リンクカードを内部リンクに対応する
> [!CAUTION]
> 循環参照の問題を解決できているかわからないので、しばらく様子をみます。
> 明らかに循環参照の場合、ビルドできないので注意です。過去の記事の参照にのみ使用するようにするとよさそうです。

現状ではshortcodeとして作成した`linkcard`は外部リンクとして指定することはできますが、同じようにして以下のように内部リンクを指定できるとうれしいと感じました。

```text
{{</* internallinkcard "posts/20250420" */>}}
```

そこで、内部リンク用に`internallinkcard`というshortcodeを作成します。

まずは、`layouts/shortcodes/internallinkcard.html`を以下のように定義します。

```html {name="layouts/shortcodes/internallinkcard.html"}
{{- $url := .Get 0}}
{{- $image := "" }}
{{- with resources.Get (.Site.Param "titleImagePath") }}
    {{- $image = .RelPermalink }}
{{- end}}
{{- partial "internallinkcard.html" (dict "url" $url "baseURL" .Site.BaseURL "page" (.Site.GetPage $url) "imagePath" $image) }}
```

さらに、`layouts/partials/internallinkcard.html`を以下のように定義します。

```html {name="layouts/partials/internallinkcard.html"}
{{- $url := urls.Parse .url }}
{{- $page := .page }}
{{- $title := "" }}
{{- $description := "" }}
{{- $image := .imagePath }}
{{- $siteURL := (urls.Parse .baseURL).Hostname }}
{{- with $page }}
    {{- $url = .RelPermalink }}
    {{- $title = .Title }}
    {{- $description = .Summary }}
{{- end }}

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

これで内部リンクを指定してlinkcardを表示することができるようになりました。

以下はサンプルです。

````text
{{</* internallinkcard "posts/20250406" */>}}
````

{{< internallinkcard "posts/20250406" >}}

## blockquoteを使えるようにする
GitHubなどでは以下のような記法でNoteやCautionなどのブロックを作ることができます。

```text
> [!NOTE]
> ノートです

> [!CAUTION]
> 注意です
```

デフォルトでは、全ての文字列が`blockquote`で囲まれて出力されます。この挙動は`layouts/_default/_markup/render-blockquote.hmtl`を書くことで変更することができます。

{{< linkcard "https://gohugo.io/render-hooks/blockquotes" >}}

以下のように変更しました。

```html {name="layouts/_default/_markup/render-blockquote.hmtl"}
{{ $emojis := dict
  "caution" ":warning:"
  "important" ":information_source:"
  "note" ":information_source:"
  "tip" ":bulb:"
  "warning" ":exclamation:"
}}

{{ if eq .Type "alert" }}
  <blockquote class="alert alert-{{ .AlertType }}">
    <p class="alert-heading">
      {{ transform.Emojify (index $emojis .AlertType) }}
      <!-- {{ with .AlertTitle }}
        {{ . }}
      {{ else }}
        {{ or (i18n .AlertType) (title .AlertType) }}
      {{ end }} -->
    </p>
    <div>
      {{ .Text }}
    </div>
  </blockquote>
{{ else }}
  <blockquote class="quote">
    {{ .Text }}
  </blockquote>
{{ end }}
```

また、CSSを以下のように当てました。

```css
/* 共通スタイル */
blockquote.alert {
  display: flex;
  border-left: 4px solid #ccc;
  padding: 5px 0;
  padding-right: 10px;
  margin: 5px 0;
  border-radius: 0.5em;
  background-color: #f9f9f9;
  font-family: sans-serif;
  position: relative;
  word-break: break-all;
}

/* 絵文字部分のスタイル */
.alert-heading {
  padding: 0 10px;
}

/* 各種アラートタイプ */
blockquote.alert-caution {
  background-color: #fff3cd;
  border-left-color: #ffe38d;
}

blockquote.alert-important {
  background-color: #d1ecf1;
  border-left-color: #9be5f1;
}

blockquote.alert-note {
  background-color: #e2e3e5;
  border-left-color: #b7c9e3;
}

blockquote.alert-tip {
  background-color: #d4edda;
  border-left-color: #9fe9b0;
}

blockquote.alert-warning {
  background-color: #f8d7da;
  border-left-color: #ff8b97;
}

.quote {
  margin: 1em 0;
  padding: 1em 1.5em;
  border-left: 4px solid #aaa;
  background-color: #f5f5f5;
  color: #333;
  font-style: italic;
  line-height: 1.6;
  border-radius: 0.25em;
}
```

完成後のサンプルは以下の通りです。

```text
> [!NOTE]
> ノートです

> [!TIP]
> Tipsです

> [!IMPORTANT]
> 重要なポイントです

> [!WARNING]
> 警告です

> [!CAUTION]
> 注意です

> 引用です
> 引用の続きです
```

> [!NOTE]
> ノートです

> [!TIP]
> Tipsです

> [!IMPORTANT]
> 重要なポイントです

> [!WARNING]
> 警告です

> [!CAUTION]
> 注意です

> 引用です
> 引用の続きです

絵文字やalertのラベルは簡単に変更できるため、適宜変えていきたいです。

## codeタグの装飾
インラインの`code`タグに装飾がないため、装飾を入れます。

コードブロックのようなrender hooksがインラインの`code`にはないようなので、`p`タグ直下の`code`タグにCSSを当てます。

```css
p code {
  background-color: #f5f5f5;
  color: #c7254e;
  font-family: Consolas, Monaco, "Courier New", monospace;
  padding: 0.2em 0.4em;
  margin: 0 0.1em;
  border-radius: 0.25em;
  font-size: 0.95em;
  word-break: break-all;
}
```

改行時の挙動は要改善かもしれませんがいい感じになりました。

## おわりに
見た目もだいぶ良くなってきました。

CSSが肥大化してきたので分割したいのですが、少し面倒もありそうです。Tailwindの導入も視野に入れています。
