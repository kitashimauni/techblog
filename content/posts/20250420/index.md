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
