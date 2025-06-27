+++
title = "Sveltia CMSを使おう"
url_title = "sveltia-cms"
date = 2025-06-27T13:29:00.000
lastmod = 2025-06-27T13:29:00.000
draft = true
tags = [ "Sveltia CMS", "HUGO" ]
+++
HUGOで実装しているこのブログにCMS(Sveltia CMS)を導入してみます。

全てCloudflare上で完結させることができるのがよいポイントです。

## 技術選定

現在のこのブログの構成は、HUGOのコア部分と記事本体が一緒のリポジトリに格納されています。

これを踏まえて、ヘッドレスCMSを調べてみたところ、以下のようなものが見つかりました。

- Netlify
- Decap CMS (Netlifyの代替)
- Sveltia CMS(Netlify/Decap CMSの代替)

一番新しいのはSveltia CMSのようなので、Sveltia CMSを使ってみます。

Sveltia CMSに関する情報はGitHubリポジトリ以外にはほとんどないため、互換性があるDecap CMSのドキュメントを合わせて参照するのがよいと思います。

{{< linkcard "https://github.com/sveltia/sveltia-cms" >}}

{{< linkcard "https://decapcms.org/docs/intro/" >}}

Sveltia CMSを使う際の注意点として、Decap CMSで使える機能が使えないことがあるという点があります。

例えば、Sveltia CMSではEditorial Workflowsが使えません。

今後実装されることに期待です。

## 前準備

これまで、以下のような命名規則で記事を作ってきました。

{{< figure src="/src/" >}}

## Sveltia CMSの導入

Sveltia CMSの導入に必要なステップを以下に記していきます。

### CMSのページを置く

HUGOの\`static/admin\`以下に次のファイルを配置します。

まずはhtmlです。ここにアクセスすることで、記事の編集ができるようになります。

```html
{name="static/admin/index.html"}
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Content Manager</title>
    <!-- Include the script that enables Netlify Identity on this page. -->
    <script src="https://identity.netlify.com/v1/netlify-identity-widget.js"></script>
  </head>
  <body>
    <!-- Include the script that builds the page and powers Decap CMS -->
    <script src="https://unpkg.com/@sveltia/cms/dist/sveltia-cms.js"></script>
  </body>
</html>
```

また、設定ファイルも同じ階層に置きます。

```yaml
backend:
  name: github
  repo: kitashimauni/techblog
  branch: main
  base_url: https://techblog-cms-auth.kitashima-daiki123.workers.dev/
# publish_mode: editorial_workflow
media_folder: "/assets"
public_folder: "/assets"
collections:
  - name: "techblog"
    label: "techblog"
    folder: "content/posts"
    media_folder: "/{{year}}{{month}}{{day}}-{{url_title}}/src"
    public_folder: "/src"
    create: true
    format: "toml-frontmatter"
    extension: "md"
    path: "{{year}}{{month}}{{day}}-{{url_title}}/index"
    fields:
      - {label: "title", name: "title", widget: "string"}
      - {label: "url_title", name: "url_title", widget: "string"}
      - {label: "date", name: "date", widget: "datetime"}
      - {label: "lastmod", name: "lastmod", widget: "datetime"}
      - {label: "draft", name: "draft", widget: "boolean", default: true}
      - {label: "tags", name: "tags", widget: "list", required: false}
      - {label: "aliases", name: "aliases", widget: "list", required: false}
      - {label: "body", name: "body", widget: "markdown"}
    view_filters:
      - label: "newpost"
        field: "url_title"
        pattern: ".*"
view_filters:
  - label: "Drafts"
    field: "draft"
    pattern: true
```
