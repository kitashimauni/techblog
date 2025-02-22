+++
title = 'ブログ制作記 #5'
date = '2025-02-18T22:41:47+09:00'
lastmod = '2025-02-22T22:41:47+09:00'
draft = false
summary = 'ブログ制作記 第5回'
tags = ['Hugo', 'Web']
+++

気になった部分の修正をしていきます。

## 決まった順にTagを並べる
マークダウンのフロントマターに`tags = ['Hugo', 'Web']`などとすると記事の始めにTagが並びますが、リストに書いた順に並ぶので一貫性がありません。

フロントマターでどのような順で買いてもTagの名前順に表示されるように変更します。

`layouts/partials/terms.html`を以下のように書き換えます。あらかじめLinkTitleの順にソートすることで実現しています。

また、後述する変更と同様に、タグの見た目を変えました。

```html
{{- $page := .page }}
{{- $taxonomy := .taxonomy }}

{{- with $page.GetTerms $taxonomy }}
  {{- $label := (index . 0).Parent.LinkTitle }}
  {{- $sorted := sort . "LinkTitle" }}
  <span>
    <div class="article-tags">
      <span>{{ $label -}}:
      {{- range $sorted }}
        <a href="{{ .RelPermalink }}" class="tag">{{ .LinkTitle }}</a>
      {{- end }}
      </span>
    </div>
  </span>
{{- end }}
```

## コピー時の挙動修正
前にコピーボタンを実装しましたが、行番号が表示されたコードブロックでコピーボタンを押すと行番号がコピーされてしまうという問題がありました。

原因は以下の通りです
- 行番号を付けると`highlight`内のコード本体の`code`タグの前に行番号の`code`タグが生成される
- `querySelector`で`code`タグを取得すると先頭にある行番号部分がコピーされる

以下のように`assets/js/main.js`において、`queryaSeletorAll`で全ての`code`タグを取得したうえで一番後ろの`code`タグをコピーするように変更します。

```js {hl_lines=["5-7"]}
// ボタンのクリックイベント
button.addEventListener("click", () => {
  if (button.innerText === "Copied!" ) return; // コピー済みの場合は何もしない

  // `.highlight` 内の最後の `<code>` を取得
  let codes = block.querySelectorAll("code")
  let code = codes[codes.length - 1].textContent;

  // クリップボードにコピー
  navigator.clipboard.writeText(code).then(() => {
  button.innerText = "Copied!";
  button.classList.add("copied");
  setTimeout(() => {
    button.classList.remove("copied");
  }, 1800); // 1秒後に戻す
  setTimeout(() => {
    button.innerText = "Copy";
  }, 2000); // 2秒後に戻す
  });
});
```

## Homeの記事一覧の見た目をいい感じにする
最新記事の一覧をホームに表示しているのですが、現状では質素すぎるので見た目をいい感じにします。

ChatGPTに考えてもらったCSSを使って`pagelist.html`を作り、`layouts/_default/home.html`と`layouts/_default/list.html`で呼び出します。

`pagelist.html`の中身は以下のようになっています。ページのリストを受けとり、それをいい感じに表示します。

```html
<div class="article-container">
  {{- $pages := .pages }}
    {{- range $pages }}
    {{ $dateHuman := .Date | time.Format "2006/01/02" }}
    <div class="article-card">
      <div class="article-content">
        <h2 class="article-title"><a href="{{ .RelPermalink }}">{{ .Title }}</a></h2>
        <p class="article-date">投稿日: {{ $dateHuman }}</p>
        <p class="article-excerpt">{{ replace (replace (string .Summary) "<p>" "") "</p>" "" }}</p>
        <div class="article-tags">
          {{- range sort (.GetTerms "tags") "LinkTitle" }}
            <a href="{{ .RelPermalink }}" class="tag">{{ .LinkTitle }}</a>
          {{ end }}
        </div>
      </div>
    </div>
  {{- end }}
</div>
```

Hugoでは以下の方法で記事にSummaryが付与されます。
- フロントマターにSummaryを書く
- 記事中に`<!--more-- >`(後ろの`-`と`>`の間に空白は入れない)と書く(この部分までがSummaryになる)
- 自動で付与される

このうち、フロントマターで書くとhtmlタグの付いていない状態で取得できるのですが、それ以外の方法だと`p`タグがついてきてしまいます。(どうしてこのような仕様にしたのか…)

Summaryを`p`タグの中に入れてクラス名でスタイルを指定しているので、その中に`p`タグを持つhtmlを入れようとすると勝手に外に出てしまい、スタイルが反映されなくなってしまいます。

良い方法がないか調べましたがあまり良い方法はなさそうなので文字列に変換した後、`p`タグを削除しています。少し力技のように感じてしまいますが、しょうがないです…。

## おわりに
修正がメインでしたが、直したいところは直せました。

他にやりたいこととしては、ページネーションの追加やちゃんとしたレスポンシブ対応等をしていきたいです。

ゆくゆくはテンプレートをサブモジュール化して簡単に使いまわせるようにしたいと考えています。
