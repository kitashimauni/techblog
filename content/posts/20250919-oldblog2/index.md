+++
title = '古のブログを作ろう デザイン編'
date = '2025-09-19T23:10:47+09:00'
draft = true
summary = 'デザインを考えます'
tags = [ "Web", "Eleventy" ]
+++

企画編に続き、今回はデザイン部分を中心に整備していきます。

## レイアウトを作成する
まず、ページ共通のヘッダーとフッターを作ります。

ヘッダー

```html {name="src/_includes/partials/header.njk"}
<header>
  <h1>古のブログ</h1>
  <hr>
</header>
```

フッター

```html {name="src/_includes/partials/footer.njk"}
<footer>
  <hr>
  <p>© 2025 古のブログ</p>
</footer>
```

次に、記事用のレイアウトを用意します。ひとまずは上部にタイトルを表示するようにしました。

```html {name="src/posts/layouts/base.njk"}
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>{{ title }}</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  {% include 'partials/header.njk' %}

  <main>
    <h1>{{ title }}</h1>
    {{ content | safe }}
  </main>

  {% include 'partials/footer.njk' %}
</body>
</html>
```

## 記事全体で共通のレイアウトを設定する
記事全体で使用するレイアウトを設定します。

`src/posts/*` にあるページ全体にレイアウトを反映させたいので、`src/posts/posts.json` に以下を書き込みます。

```json {name="src/posts/posts.json"}
{
    "layout": "layouts/posts/base.njk"
}
```

これで、`src/posts/*` にあるすべてのページで `layouts/posts/base.njk` が適用されるようになりました。フロントマターで個別に `layout` を設定すれば上書きも可能です。

> [!WARNING]
> jsonファイルを置いてそのディレクトリ以下にレイアウトを適用させたいとき、`src/_data/` ディレクトリが存在していないとレイアウトが適用されません(ここにjsonファイルを置くこともできるみたいです)。
>
> この場合、`.gitkeep` などでディレクトリを保持しておく必要があります。

## 記事一覧を表示する
記事一覧をホームに表示してみます。

ひとまず、トップページを作るため、`src/index.njk`を作成して以下のように書きます。

```html {name="src/index.njk"}
---
title: "古のブログ"
layout: "layouts/base.njk"
---

<h2>記事一覧</h2>
<ul>
{% for post in collections.posts %}
  <li>
    <a href="{{ post.url }}">{{ post.data.title }}</a>
    （{{ post.date | readableDate }}）
  </li>
{% endfor %}
</ul>
```

また、日付を `(yyyy年MM月dd日)` に変換するための `readableDate` を以下のように定義しておきます。

```js {name="eleventy.config.js"}
import { DateTime } from "luxon";

...

export default function(eleventyConfig) {
    ...
    // 日付フィルターを追加
    eleventyConfig.addFilter("readableDate", (dateObj) => {
        return DateTime.fromJSDate(dateObj, { zone: 'Asia/Tokyo' }).toFormat("yyyy年LL月dd日");
    });
};
```

これでトップページに記事一覧が表示されるようになりました。

## デザインをそれっぽくする
基本的にはCSSをいじっていきます。とはいっても、シンプルさを求めているのであまり凝ったことはしません。

```css {name="src/style.css"}
/* 背景を単色に */
body {
  background-color: #f0f0f0;
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
  /* background: #ffffff; */
  padding: 1rem;
  /* border: 1px solid #aaa; */
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

最初の状態とほとんど変えていませんが、背景を単色で統一しました。

## 設定を変更する
現状では `*.md` のみを表示するようにしていましたが、`*.html` や `*.njk` で書いた記事も載せれるようにしたいので、設定ファイルを以下のように変更します。`src/posts/**/*.{md,html,njk}` と書くことで、`src/posts` 以下にある任意の `.md` `.html` `.njk` ファイルが `posts` として検知されます。

```js {name="eleventy.config.js"}
export default function(eleventyConfig) {
    ...
    // 記事コレクションを追加
    eleventyConfig.addCollection("posts", (collection) => {
        return collection.getFilteredByGlob("src/posts/**/*.{md,html,njk}").reverse();
    });
};
```

HTMLを直書きすれば、かなり味のある記事を作れるのではないでしょうか。

## おわりに
Eleventy、いい部分は多いですが公式ドキュメントがちょっとわかりにくいです。

Markdownでサクッと記事を書くこともできるし、HTMLを直書きして味のある感じで書くこともできるのでいいのではないかと思います。
