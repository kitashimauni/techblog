+++
title = 'ブログ制作記 #4'
date = '2025-02-07T00:29:15+09:00'
lastmod = '2025-02-08T19:12:00+09:00'
draft = false
summary = 'ブログ制作記 第4回'
tags = ['Hugo', 'Web']
+++

あまり大きな変更は加えていませんが、最低限の見た目にはなってきました。

今回もやっていきます。

## Hugoのバージョンを上げる
これまでドキュメントにはあるって書いてあるのに使えないな…という機能があったのですが、どうやらバージョンを上げていなかったのが原因のようです(当たり前)。

元々は0.128.2だったものを0.143.1に上げました。Wingetを使って以下のコマンドで簡単にアップデートできました。

```bash
winget install Hugo.Hugo.Extended
```

どこか壊れないか不安でしたが、とりあえずは問題なさそうです。~~(そもそも本番環境は最新版のHugoでビルドされている気がする)~~

何と本番環境は0.118.2でビルドされていました…(デプロイでこけた)

このサイトはCloudFlareでデプロイしていますが、Hugoのバージョンを指定してビルドする際は環境変数`HUGO_VERSION`で指定できるようです([参考](https://developers.cloudflare.com/pages/framework-guides/deploy-a-hugo-site/#use-a-specific-or-newer-hugo-version))。

## ページ全体のスクロールバーの改善
縦方向にページが収まりきらない場合、何もしなくてもスクロールバーが表示されますが、表示されるときとされないときでbodyの位置がずれてしまって微妙なので直します。

とりあえずは以下を書くだけで解決できます。

```css
html {
  scrollbar-gutter: stable; /* スクロールバーを表示してもずれないようにする */
}
```

ついでにコードブロックと同じ要領でスクロールバーの見た目を変えてみました。

```css
html::-webkit-scrollbar {
  width: 10px; /* スクロールバーの幅（縦スクロール用） */
  background: #ccc; /* 背景色 */
}

html::-webkit-scrollbar-thumb {
  background: #666; /* スクロールバー本体の色 */
  border-radius: 5px; /* 丸みをつける */
}
```

## コードにコピーボタンを付ける
ここまでCSSの変更が多かったのですが、ようやくJavaScriptの出番です。

最初に作ったものはスクロールと一緒にコピーボタンが移動してしまうという致命的な問題があったので修正しました。

{{< details summary="旧バージョン">}}

テーマのフォルダの`/assets/js/main.js`に以下を書き込みます。ページの読み込み完了時にコードブロックについているクラス`highlight`をすべて見つけ、コピーボタンを配置していきます。

コピーボタンにはクリックされたときに内部のテキストをクリップボードに貼り付けるリスナーを追加しています。

```js
// コードブロックのコピーボタン
document.addEventListener("DOMContentLoaded", function () {
  // すべての `.highlight` クラスを持つ要素を取得
  document.querySelectorAll(".highlight").forEach((block) => {
    // コピーボタンを作成
    let button = document.createElement("button");
    button.innerText = "Copy";
    button.className = "copy-button";

    // コピーボタンを `.highlight` の最上部に追加
    block.style.position = "relative"; // ボタンを配置するために relative を設定
    block.appendChild(button);

    // ボタンのクリックイベント
    button.addEventListener("click", () => {
      if (button.innerText === "Copied!" ) return; // コピー済みの場合は何もしない

      // `.highlight` 内の `<code>` を取得
      let code = block.querySelector("code").textContent;

      // クリップボードにコピー
      navigator.clipboard.writeText(code).then(() => {
        button.innerText = "Copied!";
        setTimeout(() => (button.innerText = "Copy"), 2000); // 2秒後に戻す
      });
    });
  });
});
```

ついでにCSSも。(コードブロックの角も丸めてみた)

QiitaやZennに倣って、コードブロックにホバーしたときだけコピーボタンが表示されるようにしました。

```css
.copy-button {
  position: absolute;
  top: 10px;
  right: 10px;
  background: #333;
  color: white;
  border: none;
  padding: 5px 10px;
  font-size: 12px;
  cursor: pointer;
  border-radius: 4px;
  opacity: 0;
  transition: opacity 0.2s;
}

.highlight:hover .copy-button {
  opacity: 0.7;
}

.highlight:hover .copy-button:hover {
  opacity: 1;
}
```

{{< /details >}}

テーマのフォルダの`/assets/js/main.js`に以下を書き込みます。少し複雑ですが、`copy-button-container`クラスを持つ`div`タグを`highlight`クラスを持つ要素の中に入れ、`copy-button`クラスを持つ`button`を持たせています。このボタンがクリックされるとクリップボードに内容を書き込みし、一定時間後に元に戻ります。

```js
// コードブロックのコピーボタン
document.addEventListener("DOMContentLoaded", function () {
  // すべての `.highlight` クラスを持つ要素を取得
  document.querySelectorAll(".highlight").forEach((block) => {
    // コピーボタンを作成
    let button_container = document.createElement("div");
    button_container.className = "copy-button-container";
    let button = document.createElement("button");
    button.innerText = "Copy";
    button.className = "copy-button";

    // コピーボタンを `.highlight` の最上部に追加
    block.style.position = "relative"; // ボタンを配置するために relative を設定
    block.insertBefore(button_container, block.firstChild);
    button_container.appendChild(button);

    // ボタンのクリックイベント
    button.addEventListener("click", () => {
      if (button.innerText === "Copied!" ) return; // コピー済みの場合は何もしない

      // `.highlight` 内の `<code>` を取得
      let code = block.querySelector("code").textContent;

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
  });
});
```

また、CSSを以下のように指定します。`copy-button-container`に`position: sticky`を指定するのがミソです。

```css
.highlight {
  background-color: #272822;
  border-radius: 8px;
  overflow-x: auto; /* autoにすると必要な場合だけスクロールバーが出る */
  scrollbar-gutter: stable;
  width: auto;
  height: 100%;
}

.highlight > pre {
  display: flex;
}

.highlight > pre > code {
  padding: 0 10px;
}

.copy-button-container {
  position: sticky; /* スクロールしても固定 */
  left: 0;
  top: 0;
  width: 100%;
  height: 100%;
}

.copy-button {
  position: absolute;
  top: 10px;
  right: 10px;
  background: #333;
  color: white;
  border: none;
  padding: 5px 10px;
  font-size: 12px;
  cursor: pointer;
  border-radius: 4px;
  opacity: 0;
  transition: opacity 0.2s;
}

.copy-button.copied {
  opacity: 1 !important;
}

.highlight:hover .copy-button {
  opacity: 0.7;
}

.highlight:hover .copy-button:hover {
  opacity: 1;
}

.highlight:hover .copy-button.copied {
  opacity: 1 !important;
}
```

結構いい感じにできそうでいいですね。

## Homeを整える
HomeがPostsと大差ないので少し変えます。最新記事を5つ置くようにします。

テーマフォルダの`layouts/_default/home.html`を以下のようにします。

```html
{{ define "main" }}
  {{ .Content }}
  <div style="display:flex; justify-content:space-between; align-items:center;">
    <h1>最新記事の一覧</h1>
    <a href="/posts/" style="font-size:medium; font-weight: bold;">すべて見る</a>
  </div>
  {{ range (first 5 site.RegularPages) }}
    <h2><a href="{{ .RelPermalink }}">{{ .LinkTitle }}</a></h2>
    {{ .Summary }}
  {{ end }}
{{ end }}
```

## おわりに
JSを使うとさらにそれっぽくなりますね。

そろそろ、このブログに関すること以外の記事を作りたいです。