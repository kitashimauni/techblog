+++
title = 'ブログ制作記 #8'
date = '2025-04-02T20:58:30+09:00'
draft = false
summary = 'ブログ制作記 第8回'
tags = ['Hugo', 'Web']
+++

忙しかったこともあり、だいぶ期間が空きましたが続きをやっていきます。

## ブログタイトルを考える
いくら何でも「技術ブログ」は単純すぎます。

「**テック島開拓記**」と命名しました。技術の島を開拓していくという意味がこめられています(?)。

(友人の案を参考に考えました。ありがとう。)

タイトルの変更はプロジェクト直下の`hugo.toml`で`title`を書き換えればよいです。

```text {{name="hugo.toml"}}
baseURL = 'https://tech.n-island.dev/'
languageCode = 'ja-jp'
title = 'テック島開拓記'
theme = 'my-theme'
pagenate = 10
```

また、上部タイトルをクリックしてホームに戻れるように改良します。

## ハンバーガーメニューを作る
PC表示ならメニューを横並びにしても問題は起きないのですが、スマホ表示だとメニュー欄が窮屈でこれ以上増やせない状態です。

{{< figure src="./src/menu_old.png" alt="スマホ表示の現状" >}}

これを解消するため、主にCSSを書き換えることでスマホで表示した際はハンバーガーメニューになるようにします。

デザインは一旦置いておき、要件は以下のとおりです。

- スマホ表示のときのみ右上にハンバーガーメニューを置く
- ハンバーガーメニューを開いている間、それ以外の場所に触れられないようにする
- ハンバーガーメニューを開いている間、それ以外の場所に触れると閉じるようにする

ハンバーガーメニューを実装する方法はいくつもありますが、今回はチェックボックスを使う方法で実装します。

`layouts/partials/menu.html`を開き、`nav`タグ部分を以下のように書き換えます。

```html {name="layouts/partials/menu.html"}
<nav>
    <input type="checkbox" id="menu-toggle">
    <label for="menu-toggle" class="menu-icon">
        <span class="menu-open">&#9776;</span> <!-- ☰ ハンバーガー -->
        <span class="menu-close">&times;</span> <!-- ✖ 閉じる -->
    </label>
    <label for="menu-toggle" class="overlay"></label>
    <ul class="menu">
        {{- partial "inline/menu/walk.html" (dict "page" $page "menuEntries" .) }}
    </ul>
</nav>
```

`input`タグでチェックボックスを置いていて、チェックの有無でハンバーガーメニューの開閉を管理します。

また、`label`タグの`for`属性を用いてハンバーガーメニューのボタンと、ハンバーガーメニュー以外の場所へのタップをチェックボックスに紐づけています。

続いて、CSSを以下のように設定します。スマホ表示の際のみハンバーガーメニューが表示されるようにしており、見た目も若干調節しています。

```css {name="assets/css/main.css"}
/* ハンバーガーメニュー */
.menu-icon {
  display: none;
  font-size: 32px;
  cursor: pointer;
  position: absolute;
  top: 40px;
  right: 30px;
  z-index: 1001;
}

.menu-icon .menu-close {
  display: none;
  /* 初期状態は非表示 */
}

/* メニューのトグル用チェックボックス */
#menu-toggle {
  display: none;
}

/* 半透明のオーバーレイ（デフォルトは非表示） */
.overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5); /* 半透明 */
  visibility: hidden;
  opacity: 0;
  transition: opacity 0.3s ease-in-out, visibility 0.3s;
  z-index: 999;
}

/* スマホ向けレイアウト */
@media (max-width: 768px) {
  .menu-icon {
    display: block;
  }

  /* メニューの初期状態: 画面外に隠す */
  nav ul {
    display: flex;
    flex-direction: column;
    position: fixed;
    top: 0;
    right: -300px;
    /* 初期位置は画面外 */
    width: 300px;
    height: 100%;
    background: white;
    border-left: 1px solid #ccc;
    padding: 20px;
    padding-top: 100px;
    transition: right 0.3s ease-in-out;
    box-shadow: -2px 0 5px rgba(0, 0, 0, 0.2);
    z-index: 1000;
  }

  nav ul li {
    margin: 15px 0;
  }

  nav ul li a {
    font-size: 20px;
  }

  /* メニューが開いたとき */
  #menu-toggle:checked + .menu-icon + .overlay {
    visibility: visible;
    opacity: 1;
  }
  #menu-toggle:checked + .menu-icon + .overlay + ul {
    right: 0;
  }


  /* ☰ → ✖ に切り替え */
  #menu-toggle:checked+.menu-icon .menu-open {
    display: none;
  }

  #menu-toggle:checked+.menu-icon .menu-close {
    display: block;
  }
}
```
