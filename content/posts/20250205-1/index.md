+++
title = 'ブログ制作記 #2'
date = '2025-02-05T21:00:16+09:00'
draft = false
summary = 'HugoでAboutページの作成、ページ全体の中央寄せ、タグ表示の改善、コードブロックの横スクロール対応を実装します'
tags = [ "Hugo", "Web" ]
aliases = [ "/posts/20250205" ]
+++

引き続きブログの改善に臨みます。

## Aboutページの制作
デフォルトの状態ではAboutがないのでAboutのページを作ります。

テンプレートの`hugo.toml`に以下を追記します。

```toml
[[menus.main]]
name = 'About'
pageRef = '/about'
weight = 40
```

そして、`content/about/_index.md`にAboutの内容を書き込んでいきます。

ここで、アイコン画像を並べるために要素を横並びで表示するshortcodeを書いてみました。引数に`class`があればそちらを優先するようにしたのですが、その場合gridではなくなるので微妙な実装かもしれません。
```html
{{ if .Get "class" }}
    {{ $class = .Get "class" }}
    <div class="{{ $class }}">
    {{ .Inner }}
    </div>
{{ else }}
    <div style="display: flex; flex-wrap: wrap;">
        {{ .Inner }}
    </div>
{{ end }}
```

これは備忘録的に書いておくのですが、マークダウンから引数でCSSを受け取ってそれをstyleに代入する際は、`style="{{ .Get "style" | safeCSS }}"`のように[safeCSS](https://gohugo.io/functions/safe/css/)にパイプしないとこの部分が`ZgotmplZ`となってしまいます。

不正なインジェクションを防ぐためのGoの仕様らしいです。あまり多様するのはよくなさそうなのでいったんやめました。

## 中央に寄せる
現状だと全てのページが左に寄っています。スマホやタブレットで見る分には問題ないですが、PCで見ると明らかに左に寄っていて見ずらいです。

なのでCSS(テンプレートの`assets/css/main.css`)に以下を追記してページ全体を中央に寄せました。余白を付けるのも忘れずに
```css
html, body {
  margin: auto; /* 横の中央揃え */
  justify-content: center; /* 水平方向の中央揃え */
  padding: 1rem; /* 余白 */
}
```

## タグを上にもってくる
現状ではこんな感じで下に記事のタグが置かれていますが、上にあったほうがいいと思ったので上にもっていきます。

{{< figure src="./src/20250205.png" alt="現状のタグの表示">}}

`layouts/_default/single.html`をこんな感じにして`layouts/partials/terms.html`がコンテンツの上に置かれるようにします。

```html
{{ define "main" }}
  <h1>{{ .Title }}</h1>

  {{ $dateMachine := .Date | time.Format "2006-01-02T15:04:05-07:00" }}
  {{ $dateHuman := .Date | time.Format "2006/01/02" }}
  <p>投稿日
    <time datetime="{{ $dateMachine }}">{{ $dateHuman }}</time>
    {{ if ne .Lastmod .Date }}
      {{ $updateDate := .Lastmod | time.Format "2006/01/02" }}
      <br>
      (最終更新:<time datetime="{{ $dateMachine }}">{{ $updateDate }}</time>)
    {{ end }}
    <br>
    {{ partial "terms.html" (dict "taxonomy" "tags" "page" .) }}
  </p>

  {{ .Content }}
{{ end }}

```

Web初心者なので初めて知りましたが、pタグの中にdivタグを置くと勝手に外に出てしまうんですね。`terms.html`が中でdivタグを使っていたのでspanタグに変更しました。

ついでに、タグの表示方法も変えてみました。カンマ区切りでタグを横に並べています。(最後のタグの後にカンマを置かないようにするの、もっといい実装ないですかね？)

```html
{{- $page := .page }}
{{- $taxonomy := .taxonomy }}

{{- with $page.GetTerms $taxonomy }}
  {{- $label := (index . 0).Parent.LinkTitle }}
  <span>
    <span>{{ $label }}:
      {{- range . }}
        <a href="{{ .RelPermalink }}">{{ .LinkTitle }}</a>
        {{ if ne . (index (last 1 ($page.GetTerms $taxonomy)) 0) }}, {{ end }}
      {{- end }}
    </span>
  </span>
{{- end }}
```

## コードブロックの改善
スマホでこのサイトを確認していたら、コードブロックが横に突き出してひどいことになっていました。たまにこうなってるサイトを見かけますが、何もしないとこうなるのか…という気持ちです。

これを直すには横がはみ出たときに横スクロールにするのがよさそうです。コードブロックに当たっていた`highlight`に自動でスクロールにする設定を追加します。

```css
.highlight {
  padding: 1px 10px;
  background-color: #272822;
  overflow-x: auto; /* 自動でスクロールに */
  scrollbar-gutter: stable;
}
```

`hugo gen chromastyles`コマンド([ドキュメント](https://gohugo.io/commands/hugo_gen_chromastyles/))でシンタックスハイライト用のスタイルシートを生成できるらしいのですが、何も設定しなくてもシンタックスハイライトが効いているのでひとまずはこれでいきます。

## おわりに
「おわりに」みたいなものを置かないとどこまでが本題かわかりずらいですね。

今回も些細な修正でしたが、また少し見た目が良くなったと思います。三日坊主にならないように続けたいものです。
