+++
title = 'ブログ制作記 #1'
date = '2025-02-04T20:42:30+09:00'
lastmod = '2025-02-05T17:02:30+09:00'
draft = false
summary = ''
tags = [ "Hugo", "Web" ]
+++

せっかくブログを作ったので制作の記録を書こうと思います。

<!--more-->

{{< details summary="余談" >}}
これはshortcodeを使って書かれています。(使ってみたかった)

ところでブログでは「だ/である」調と「です/ます」調のどちらで書くのがいいのでしょうか？

説明するときは「だ/である」調のほうが書きやすい気がしますが…

しばらくは混ざった感じになってしまいそうです。
{{< /details >}}

# 本題
このブログは以下のコマンドを打った状態から始めています。

```bash
hugo new site techblog
hugo new theme my-theme
```


Hugoの素のテンプレートから作り始めたため、最初は本当に何もないです。Hugoを触るのも初めてなので細かいところから変更を加えていきます。

今回変更を加えるのは`themes/my-theme`の部分です。何度かパスが出てきますが、それらはmy-themeフォルダ内のパスとなっています。(`my-theme`は適当に付けた名前なので後で名前を変えるかもしれません)

序盤に変更した内容を以下に記します。ときどき直したいものにコメントを入れてますが、後々見たときには直ってるといいな…。

## 日時表記を変える
デフォルトでは投稿日の表記が"March 15, 2023"のようになっていたので投稿日時をyyyy/mm/ddで表記するように変更しました。ついでに最終更新日時も表記しています。

`layouts/_default/single.html`を以下のように変更します。
最終更新日時はフロントマターで`lastmod`に値を入れておくと`.Lastmod`で取得できます。

```html {linenos=table,hl_lines=[8,"5-13"]}
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
  </p>

  {{ .Content }}
  {{ partial "terms.html" (dict "taxonomy" "tags" "page" .) }}
{{ end }}
```

コピーしても行番号が入らないようになっているのはポイント高いです。コピーボタンとかファイル名表示とかも欲しいですね。

## コードブロックの余白を増やす
上の部分を書いていて、コードブロックの余白が小さすぎると感じたので余白を増やしました。コードブロックに`highlight`というクラスがついてたので`padding`して同じ色の背景を入れています。

~~生成されたHTMLのコードブロックの部分を見るとTailwindが使われてるっぽいです。~~

タグに`style`が書かれているだけだった。

`assets/css/main.css`
```css
.highlight {
  padding: 1px 10px;
  background-color: #272822;
}
```

## メニューにスタイルを付ける
何もしないと適用されるCSSが全く無いのでこんな感じになってしまいます。
{{< figure
  src="./src/20250204-2-1.png"
  alt="何も設定しない場合のメニュー"
>}}
`assets/css/main.css`に以下を追記して見た目が少し良くなりました。
```css
nav ul {
  display: flex; /* 横並び */
  list-style: none; /* 箇条書きの点を消す */
  padding: 8px 0;
  margin: 0; /* ナビゲーション全体の上下の余白 */  
}

nav li {
  margin: 0 5px; /* 各項目の間隔を調整 */
}

nav a {
  text-decoration: none; /* 下線を消す */
  font-size: large;
  color: #333;
  padding: 8px 15px;
  border-radius: 5px;
  transition: all 0.3s;
}

nav a:hover {
  background: #eee;
}
```
ここは全体の見た目を変えるときに調整すると思います。

## タグの一覧表示を改善する
[この]({{< ref "/tags" >}})タグの一覧表示も、デフォルトだと変な感じなので変えました。

`layouts/taxonomy/terms.html`を新しく作成し、以下のように書きます。これによって、タグが記事の多い順に並び、記事数もタグの横に表示されるようになりました。
```html
{{ define "main" }}
  <div>
    <h2>{{ .Title }}</h2>
    {{ .Content }}
    <ul>
    {{ range .Data.Terms.ByCount }}
      <li><a href="{{ .Page.RelPermalink }}">{{ .Page.LinkTitle }}({{ .Count }})</a></li>
    {{ end }}
    </ul>
  </div>
{{ end }}
```

いい感じになりました。必ず始めが大文字になるのはどうなのか…。CSSを付けてもう少し見た目も良くしたいですね。

(ビルドしたら大文字じゃなくなった…謎)

{{< figure
  src="./src/20250204-2-2.png"
  alt="改善後のTags"
>}}

ひとまずはこんな感じで終わります。本当に最低限ですが見た目は良くなったと思います。

まだまだ改善の余地があるのでHugoを学びながら少しずつよくしていきたいです。(この下のタグ表記も上に持っていきたい)
