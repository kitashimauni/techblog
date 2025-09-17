+++
title = '古のブログを作ろう 企画編'
date = '2025-09-16T20:57:19+09:00'
draft = false
summary = '古のブログサイトを作りたい'
tags = [ "Web" ]
+++

忙しくて全く更新できていませんが、最低でも月1回の投稿を目指します。

## 古のブログを作りたい
近年、WEBフレームワークの登場やCSSの多機能化により、リッチな見た目のWEBサイトを簡単に作れるようになりました。

その一方、過去の古めかしい見た目のWEBサイトはプロバイダのサービス終了などにより姿を消しつつあります。

懐かしい気持ちにしてくれる、この古めかしいサイトを自分で作りたいと思ったのでやっていきます。

(正直このサイトも背景が真っ白なのでなんとかしたい)

## 古のブログの要件
デザインを考えるうえで、古のブログの特徴を挙げてみます。

- 背景が単色
- シンプルなデザイン
- アクセスカウンター
- 掲示板や拍手機能

だいぶアバウトですが、基本的にはこれに沿って作っていきたいです。

ただし、これに寄せるあまり見づらくなったり使いにくくなったりしないように気を付けます。

## 技術選定
静的サイトジェネレーターを使用します。Eleventyという(有名な？)SSGがあるみたいなので、これを使ってみようと思います。

また、ホスティングはこのブログと同じでCloudflare Pagesで行い、アクセスカウンターなどの情報を保持しなければならない部分についてもCloudflareの機能を使いたいです。


## 試しに実装
以下の公式サイトを参考にやってみます。ファイル数が多くてもビルドが早いのが売りのようです。

{{< linkcard "https://www.11ty.dev/" >}}

### プロジェクトの作成
特に初期化等は必要なさそうです。試しに `index.md` を作ります。

```md {name="index.md"}
# Heading
```

この状態で以下のコマンドを実行すれば `http://localhost:8080/` で確認できます (v18以上のNode.jsが必要です)。

```bash
npx @11ty/eleventy --serve
```

以下のように表示されました。マークダウンが問題なく変換されているようです。

{{< figure src="src/first.png " alt="Headingが表示されている" >}}

かなりシンプルで、求めているものが簡単に作れそうです。

一応 `package.json` を作っておきます。

```bash
npm init -y
npm pkg set type="module"
npm install @11ty/eleventy
```

### 設定ファイルの作成
ディレクトリ直下に設定ファイルを作成します。作成するファイルは `src` に、生成したファイルは `public` に出力されるように設定します。

```js {name=eleventy.config.js}
export const config = {
    dir: {
        input: 'src',
        output: 'public',
    },
};
```

この上で、出力されるファイルはgitに上げなくていいので `.gitignore` を以下のように書きます。

```text {name=".gitignore"}
public
```

### テンプレートを作ってみる
テンプレートを作ってみます。`src/_includes/layouts/base.njk` に以下を書き込みます。

```html {name="src/_includes/layouts/base.njk"}
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>{{ title }}</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <header>
    <h1>古のブログ</h1>
    <hr>
  </header>

  <main>
    {{ content | safe }}
  </main>

  <footer>
    <hr>
    <p>© 2025 古のブログ</p>
  </footer>
</body>
</html>
```

また、CSSを以下のように書き込みます。

```css {name="src/style.css"}
/* 背景を単色に */
body {
  background-color: #f0f0f0;  /* 薄いグレー */
  color: #000;
  font-family: "Courier New", monospace; /* 等幅でレトロ感 */
  line-height: 1.6;
  margin: 0;
  padding: 1rem;
}

/* 見出しは下線で区切る */
h1, h2, h3 {
  border-bottom: 1px solid #000;
  padding-bottom: 0.25rem;
}

/* 中央寄せ・幅制限 */
main {
  max-width: 700px;
  margin: 0 auto;
  background: #fff;
  padding: 1rem;
  border: 1px solid #aaa;
}

/* リンクは昔風ブルー */
a {
  color: blue;
  text-decoration: underline;
}
a:visited {
  color: purple;
}

/* フッターは小さめ文字 */
footer {
  font-size: 0.8rem;
  text-align: center;
  margin-top: 2rem;
}
```

加えて、CSSを反映させるために設定ファイルに追記します。

```js {name="eleventy.config.js"}
export default function(eleventyConfig) {
    eleventyConfig.addPassthroughCopy("src/style.css");
    eleventyConfig.addWatchTarget('src/style.css');
};
```

あとは、`index.md` にlayoutを反映させるため、以下のように書き換えます。

```md {name="src/index.md"}
---
layout: layouts/base.njk
title: Home
---

# Heading
```

これで、確認すると以下のようになりました。いい感じなのではないでしょうか。

{{< figure src="src/after.png" alt="テンプレートやCSSを反映させたあとの画像" >}}

## おわりに
Eleventyは初めて触れましたが、様々な言語でテンプレートを作れるなど、シンプルかつ高機能といった印象です。これで作っていこうと思います。

作って何に使うかですが、アニメやゲームのレビューなどを書けるといいかなと思っています。


