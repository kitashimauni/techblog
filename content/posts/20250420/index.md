+++
title = 'ブログ制作記 #10'
date = '2025-04-20T00:27:08+09:00'
draft = true
summary = 'ブログ制作記 第10回'
tags = ['Hugo', 'Web']
+++

TODO: ここに書く

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

### リンクカードを内部リンクに対応する
> [!CAUTION]
> 循環参照の問題を解決できなかったため一旦諦めます。

現状ではshortcodeとして作成した`linkcard`は外部リンクとして指定することはできますが、同じようにして以下のように内部リンクを指定できるとうれしいと感じました。

```text
{{</* internallinkcard "posts/20250420" */>}}
```

そこで、内部リンク用に`internallinkcard`というshortcodeを作成します。`linkcard`との違いを比べると`site.Home.Permalink`が先頭についているかどうか以外の違いがありません。

`internallinkcard`の中で`linkcard`を呼び出せればよいのですが、shortcodeの中でshortcodeを呼び出すことは難しいようです。解決策として、今の`shortcodes/linkcard.html`を`partials/linkcard.html`に移植し、`shortcodes/linkcard.html`と`shortcodes/internallinkcard.html`から`partials/linkcard.html`を呼び出すという構造に変更します。

3ファイルを以下のように変更します。partial呼び出しの引数には`dict`を使います。

```html {name="layouts/shortcodes/linkcard.html"}
{{- partial "linkcards.html" (dict "url" (.Get 0)) }}
```

`internallinkcard`では`site.Home.Permalink`を結合してpartialを呼び出します。

```html {name="layouts/shortcodes/internallinkcard.html"}
{{- $rel_url := .Get 0 }}
{{- $url := urls.JoinPath site.Home.Permalink $rel_url }}
{{- partial "linkcards.html" (dict "url" $url) }}
```

`layouts/shortcodes/linkcard.html`から`layouts/partials/linkcard.html`へコピー後の変更は先頭の一行のみです。

```html {name="layouts/partials/linkcard.html (変更部分)"}
{{- $url := urls.Parse .url }}
```

これで内部リンクを指定してlinkcardを表示することができるようになりました。

以下はサンプルです。

````text
{{</* internallinkcard "posts/20250420" */>}}
````

<!-- {{< internallinkcard "posts/20250420" >}} -->

<!-- TODO: codeの装飾 -->
<!-- TODO: blockquoteの有効化 -->