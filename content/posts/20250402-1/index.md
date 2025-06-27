+++
title = 'ブログ制作記 #8'
date = '2025-04-02T20:58:30+09:00'
draft = false
summary = 'ブログ制作記 第8回'
tags = [ "Hugo", "Web" ]
aliases = [ "/posts/20250402" ]
+++

忙しかったこともあり、だいぶ期間が空きましたが続きをやっていきます。

## ブログタイトルを考える
いくら何でも「技術ブログ」は単純すぎます。

「**テック島開拓記**」(てっくとうかいたくき or てっくしまかいたくき or てっくじまかいたくき)

と命名しました。技術の島を開拓していくという意味がこめられています(?)。

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

`layouts/partials/header.html`を以下のように書き換えることで、サイト上部のタイトル部分を画像にできるようにしました。

```html {name="layouts/partials/header.html"}
{{ with resources.Get (.Site.Param "titleImagePath") }}
  <a href={{ site.Home.Permalink }}>
    <img class="title-image" src="{{ .RelPermalink }}" alt="Title Image">
  </a>
{{ else }}
  <h1 class="site-title">
    <a href={{ site.Home.Permalink }}>{{ site.Title }}</a>
  </h1>
{{ end }}
{{ partial "menu.html" (dict "menuID" "main" "page" .) }}
```

このように変更したうえで`assets/images/title.png`などの画像を置き、`hugo.toml`に以下のように書き込むとタイトル部分が画像になります。
```toml {name="hugo.toml"}
[params]
titleImagePath = 'images/title.png'
```

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
  top: 20px;
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
  background: rgba(0, 0, 0, 0.5);
  /* 半透明 */
  visibility: hidden;
  opacity: 0;
  transition: opacity 0.3s ease-in-out, visibility 0.3s;
  z-index: 999;
}

/* スマホ向けレイアウト */
@media (max-width: 768px) {
  .menu-icon {
    display: block;
    position: fixed;
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
    padding: 0;
    padding-top: 100px;
    transition: right 0.3s ease-in-out;
    box-shadow: -2px 0 5px rgba(0, 0, 0, 0.2);
    z-index: 1000;
  }

  nav ul li {
    margin: 15px 0;
    width: 100%;
  }

  nav ul li a {
    display: block;
    font-size: 20px;
    width: 100%;
  }

  /* メニューが開いたとき */
  #menu-toggle:checked+.menu-icon+.overlay {
    visibility: visible;
    opacity: 1;
  }

  #menu-toggle:checked+.menu-icon+.overlay+ul {
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

/* メニューオープン中に body に追加されるクラス */
.no-scroll {
  overflow: hidden;
  height: 100vh; /* iOS対策 */
}
```

ハンバーガーメニューを開いたときに背景をスクロールできないようにするため、以下のJSを書いてチェックボックスがオンの時に`no-scroll`をbodyに付与してスクロールしないようにします。

```js {name="assets/js/main.js"}
// ハンバーガーメニューを開いているときにスクロールを無効にする
document.addEventListener('DOMContentLoaded', function () {
  const menuToggle = document.getElementById('menu-toggle');

  menuToggle.addEventListener('change', function () {
    if (menuToggle.checked) {
      document.body.classList.add('no-scroll');
    } else {
      document.body.classList.remove('no-scroll');
    }
  });
});
```

## ハンバーガーメニューのマークにアニメーションを付ける
前章でハンバーガーメニューを付けましたが、アニメーションが欲しくなったので付けてみます。

まずは`layouts/partials/menu.html`に書かれている`nav`タグの部分を以下のように変更します。

```html {name="layouts/partials/menu.html"}
<nav>
<input type="checkbox" id="menu-toggle">
<label for="menu-toggle" class="menu-icon">
    <div class="hamburger"></div>
</label>
<label for="menu-toggle" class="overlay"></label>
<ul class="menu">
    {{- partial "inline/menu/walk.html" (dict "page" $page "menuEntries" .) }}
</ul>
</nav>
```

そのうえで、`assets/css/main.css`を以下のように書き換えます。

```css {name="assets/css/main.css"}
/* ハンバーガーメニュー */
.menu-icon {
  display: none;
  font-size: 32px;
  cursor: pointer;
  position: absolute;
  top: 25px;
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
  background: rgba(0, 0, 0, 0.5);
  /* 半透明 */
  visibility: hidden;
  opacity: 0;
  transition: opacity 0.3s ease-in-out, visibility 0.3s;
  z-index: 999;
}

/* スマホ向けレイアウト */
@media (max-width: 768px) {
  .menu-icon {
    display: block;
    position: fixed;
    cursor: pointer;
    margin: auto;
    height: 50px;
    -webkit-tap-highlight-color: transparent;
    outline: none;
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
    padding: 0;
    padding-top: 100px;
    transition: right 0.3s ease-in-out;
    box-shadow: -2px 0 5px rgba(0, 0, 0, 0.2);
    z-index: 1000;
  }

  .menu-icon .hamburger {
    background: black;
    width: 30px;
    height: 3px;
    position: relative;
    transition: background 10ms 200ms ease;
    transform: translateY(20px);
  }
  .menu-icon .hamburger:before, .menu-icon .hamburger:after {
    transition: top 200ms 250ms ease, transform 200ms 50ms ease;
    position: absolute;
    background: black;
    width: 30px;
    height: 3px;
    content: "";
  }
  .menu-icon .hamburger:before {
    top: -10px;
  }
  .menu-icon .hamburger:after {
    top: 10px;
  }
  
  #menu-toggle:checked ~ .menu-icon .hamburger {
    background: transparent;
  }
  #menu-toggle:checked ~ .menu-icon .hamburger:after, #menu-toggle:checked ~ .menu-icon .hamburger:before {
    transition: top 200ms 50ms ease, transform 200ms 350ms ease;
    top: 0;
  }
  #menu-toggle:checked ~ .menu-icon .hamburger:before {
    transform: rotate(45deg);
  }
  #menu-toggle:checked ~ .menu-icon .hamburger:after {
    transform: rotate(-45deg);
  }

  nav ul li {
    margin: 15px 0;
    width: 100%;
  }

  nav ul li a {
    display: block;
    font-size: 20px;
    width: 100%;
  }

  /* メニューが開いたとき */
  #menu-toggle:checked+.menu-icon+.overlay {
    visibility: visible;
    opacity: 1;
  }

  #menu-toggle:checked+.menu-icon+.overlay+ul {
    right: 0;
  }
}

/* メニューオープン中に body に追加されるクラス */
.no-scroll {
  overflow: hidden;
  height: 100vh; /* iOS対策 */
}
```

以下のサイトを参考にさせていただきました。

{{< linkcard "https://photopizza.design/css_hamburger_menu/" >}}

## 選択時に水色になるのをなくす
CSSのデフォルト設定で、画像やリンクを触ったときに水色になってしまいます。これをなくすために、`assets/css/main.css`に以下を書き込みました。

```css {name="assets/css/main.css"}
a, button, input, textarea, label, img {
  -webkit-tap-highlight-color: transparent;
  outline: none;
}
```

## おわりに
レスポンシブ対応もできてばっちりです。そろそろデザインを凝っていきたいです。
