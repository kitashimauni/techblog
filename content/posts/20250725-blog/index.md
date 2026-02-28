+++
title = 'ブログ制作記 #12'
date = '2025-07-25T14:55:52+09:00'
draft = false
summary = 'Pagefindを使ってHugoブログに日本語対応の全文検索機能を追加します'
tags = [ "Hugo", "Web" ]
+++

久々にブログ自体に手を入れていきます。

## 全文検索機能の追加
半ば断念していた検索機能の追加ですが、Pagefindを使って実装してみようと思います。

まず、Pagefind用のCSSとJSを読み込む以下の`html`を`head`に書き込みます。

```html {name="layouts\partials\head.html"}
<!-- Pagefind Search Integration -->
<link href="/pagefind/pagefind-ui.css" rel="stylesheet">
<script src="/pagefind/pagefind-ui.js"></script>
<script>
    window.addEventListener('DOMContentLoaded', (event) => {
        new PagefindUI({
            element: "#search",
	    showImages: false,
	    translations: {
                clear_search: "消去",
                zero_results: "[SEARCH_TERM]の検索結果はありません",
                alt_search: "[SEARCH_TERM]の検索結果はありませんでした。[DIFFERENT_TERM]の検索結果を表示しています",
                search_suggestion: "[SEARCH_TERM]の検索結果はありませんでした。次のいずれかの検索を試してください",
            }
        });
    });
</script>
```

次に、検索欄を配置します。

このブログの検索欄は、メニューから選択できる独立したページに配置することにします。

まず、メニューを追加するために`hugo.toml`に以下を追記します。

```toml {name="hugo.toml"}
[[menus.main]]
name = 'Search'
pageRef = '/search'
weight = 25
```

次に、Searchのページを追加します。ここに検索欄も配置します。

`rawhtml`は、マークダウン内に素の`html`を埋め込むために作成した`shortcodes`です。

```md {name="content\search\_index.md"}
+++
title = 'Search'
date = 2023-01-01T08:30:00-07:00
draft = false
+++

{{</* rawhtml */>}}
<div id="search"></div>
{{</* /rawhtml */>}}
```

一応、`rawhtml`の実装も載せておきます。とても簡単です。

```html {name="layouts/shortcodes/rawhtml.html"}
{{ .Inner }}
```

次に、インデックスファイルの生成を行います。`npx`を使うかGitHubから直接バイナリをダウンロードするかしてPagefindを用意します。このとき、`pagefind_extended`を入れることで日本語に対応させることができます。

私はGitHubから直接バイナリをダウンロードし、パスを通しておきました。

{{< linkcard "https://github.com/Pagefind/pagefind/releases" >}}

そして、以下のコマンドを実行します。ビルドのたびにPagefindを実行しなくてもいいように、`static/pagefind`に生成します。

```bash
hugo # 一度もhugoコマンドを実行したことがない場合
pagefind_extended --site public --glob="{posts}/*/*.html" --output-path="static/pagefind"
```

このコマンドを実行した後、サーバーを立てて確認してみます。

```bash
hugo server
```

"/search"に検索欄が表示されるようになりました。もちろん、検索もできます。

{{< figure src="./src/search.png" alt="検索欄" >}}

あとは、デプロイ周りの設定をします。

デプロイ時にPagefindを実行するため、以下のシェルスクリプトを作成しました。`pagefind_extended`の実行コマンドのオプションが少し異なっていることに注意してください。

```sh {name="indexpage.sh"}
#!/bin/bash

echo "Generating index page with Pagefind..."

wget https://github.com/Pagefind/pagefind/releases/download/v1.3.0/pagefind_extended-v1.3.0-x86_64-unknown-linux-musl.tar.gz
tar -zxvf pagefind_extended-v1.3.0-x86_64-unknown-linux-musl.tar.gz
./pagefind_extended --site public --glob="{posts}/*/*.html"

echo "Index page generated successfully."
```

上記のシェルスクリプトをデプロイ時に実行するため、ビルドコマンドを以下のように変更します。

```sh
hugo && chmod +x ./indexpage.sh && ./indexpage.sh
```

以下の記事を参考にさせていただきました。

{{< linkcard "https://zenn.dev/k1350/articles/42c13020038d4c" >}}

## おわりに
今回は全文検索機能を追加しました。Pagefindはクライアントサイドで動作するため、サーバーが必要ないというのがいい点です。

ここには載せなかったのですが、Google Analyticsも導入しました。
