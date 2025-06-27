+++
title = 'ブログ制作記 #6'
date = '2025-02-22T14:23:49+09:00'
draft = false
summary = 'ブログ制作記 第6回'
tags = [ "Web", "Hugo" ]
aliases = [ "/posts/20250222" ]
+++

見た目の変更を主にやっていきます。

## タグ一覧の見た目を変える

前回、記事のタグ表示を変えましたが、タグ一覧ではまだ変更がされていませんでした。

そこで、タグ一覧の見た目も変えることにしました。
タグ一覧の見た目を変える場合、今までは`layouts/taxonomy/terms.html`に記述していましたが、これからは`layouts/tags/taxonomy.html`に記述するようにします。Hugoのディレクトリ階層やテンプレートがどのような順で適用されるかについてはHugoのドキュメント([ここなど](https://gohugo.io/templates/types/))に記載されていますが、完全には理解できていません。もう少しちゃんと勉強したいです。

`layouts/tags/taxonomy.html`に以下を記述します。これでCSSもあたって見た目も良くなりました。

```html {name="layouts/tags/taxonomy.html"}
{{ define "main" }}
  <div>
    <h1>{{ .Title }}</h1>
    {{ .Content }}
    <div class="tag-container">
      {{ range .Data.Terms.ByCount }}
        <a href="{{ .Page.RelPermalink }}" class="tag-card">
          <span class="tag-name">{{ .Page.LinkTitle }}</span>
          <span class="tag-count">{{ .Count }}</span>
        </a>
      {{ end }}
    </div>
  </div>
{{ end }}
```

また、各タグのページ一覧の見た目も少しだけ変えます。これは`layouts/tags/terms.html`に記述します。

これまではタグ名しか表示されておらず何のページかがわかりずらかったためこのようにしました。

```html {name="layouts/tags/terms.html"}
{{ define "main" }}
  <h1>{{ .Title }} の記事一覧</h1>
  {{ partial "pagelist.html" (dict "pages" .Pages) }}
{{ end }}
```

以下CSSです。

{{< details summary="CSS" >}}
```css
.tag-container {
  display: flex;
  flex-wrap: wrap;
  gap: 15px;
  justify-content: center;
}
.tag-card {
  background: #007bff;
  border-radius: 8px;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
  padding: 5px 10px;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: transform 0.2s ease-in-out;
}
.tag-card:hover {
  transform: scale(1.05);
}
.tag-name {
  font-size: 16px;
  font-weight: bold;
  color: #ffffff;
  text-decoration: none;
}
.tag-name:hover {
  text-decoration: underline;
}
.tag-count {
  background-color: #7abafb;
  color: white;
  font-size: 14px;
  font-weight: bold;
  padding: 3px 5px;
  border-radius: 8px;
}
```
{{< /details >}}

## コードブロックにファイル名を表示できるようにする
これまでコードブロックではスクロール関係のCSSを当てたり、コピーボタンを実装したりしました。

もう一声、ファイル名を表示できるようにします。

Hugoではマークダウンでコードブロックを書いたときのレンダリングを自分で書くことができます([参考](https://gohugo.io/render-hooks/code-blocks/))。
具体的には、`layouts/_defaults/_markup/render-code.html`に出力したいものを書き込めばよいです(言語ごとに設定することもできます)。

デフォルトの出力は以下のコードと同じです。

```html {name="layouts/_defaults/_markup/render-code.html"}
{{ $result := transform.HighlightCodeBlock . }}
{{ $result.Wrapped }}
```

ここに手を加えてファイル名をコードブロックの上に表示できるようにします。まずは、以下のように書き換えました。`name`が指定されていた場合、ファイル名を表示する部分をレンダリングします。
```html {name="layouts/_defaults/_markup/render-code.html"}
{{ $result := transform.HighlightCodeBlock . }}
<div class="code-container">
  {{ with .Attributes.name }}<div class="file-name">{{ . }}</div>{{ end }}
  {{ $result.Wrapped }}
</div>
```

以下CSSです。

{{< details summary="CSS" >}}
```CSS
.code-container {
  border-radius: 8px;
  overflow: hidden;
}

.file-name {
  background: #3a3f4b;
  color: #ffffff;
  font-size: 13px;
  padding: 7px 12px;
  font-weight: bold;
}
```
{{< /details >}}

これでファイル名を指定した場合はコードブロックの上にファイル名が表示されるようになりました。

使い方は以下のように`name`属性を付けるだけです。
````md
```py {name="hello.py"}
print("Hello World!!")
```
````
結果は以下のようになります。しっかりファイル名を表示できています。

```py {name="hello.py"}
print("Hello World!!")
```

## おわりに
ひとまずの完成にかなり近づいてきました。

今後やりたいことは以下の通りです。

- メニューの改善(スマホにおけるハンバーガーメニューの実装)
- 検索機能の実装
