+++
title = 'ブログ制作記 #9'
date = '2025-04-06T22:46:47+09:00'
draft = true
summary = 'ブログ制作記 第9回'
tags = ['Hugo', 'Web']
+++

## ハンバーガーメニュー周りの改善
### オーバーレイの連続タップ対策
ハンバーガーメニューを開いているとき、背景にオーバーレイをかけてそこをタップするとメニューが閉じるようにしていますが、これを連続してタップすると閉じずに開いたままになってしまいます。

これは、forでチェックボックスに紐づけているのが原因です。この問題を修正するため、オーバーレイのタップに対する処理をJSで制御してメニューを閉じることしかしないようにします。

まずはHTMLを以下のように書き換えます。メニュー部分が記述された`layouts/partials/menu.html`の`nav`タグ部分を以下のようにします。オーバーレイのタップをチェックボックスに紐づけないように変更しました。

```html {name="layouts/partials/menu.html"}
<nav>
  <input type="checkbox" id="menu-toggle">
  <label for="menu-toggle" class="menu-icon">
    <div class="hamburger"></div>
  </label>
  <label class="overlay"></label>
  <ul class="menu">
    {{- partial "inline/menu/walk.html" (dict "page" $page "menuEntries" .) }}
  </ul>
</nav>
```

続いてJSのハンバーガーメニューに関する記述を以下のように書き換えます。オーバーレイをタップした際にチェックボックスのチェックを外す処理を書き加えました。

```js {name="assets/js/main.js"}
// ハンバーガーメニューを開いているときにスクロールを無効にする
document.addEventListener('DOMContentLoaded', function () {
  const menuToggle = document.getElementById('menu-toggle');
  const overlay = document.getElementsByClassName('overlay')[0];

  menuToggle.addEventListener('change', function () {
    if (menuToggle.checked) {
      document.body.classList.add('no-scroll');
    } else {
      document.body.classList.remove('no-scroll');
    }
  });

  overlay.addEventListener('click', function () {
    menuToggle.checked = false;
  });
});
```

{{< details summary="ナビゲーション部分のCSS" >}}

```css {name="assets/css/main.css"}
/* ハンバーガーメニュー */
.menu-icon {
  display: none;
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
    top: 30px;
    right: 20px;
    cursor: pointer;
    height: 33px;
    padding: 5px;
    z-index: 1001;
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
    transform: translateY(10px);
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
```

{{< /details >}}

## robots.txtを追加する
現状では`robots.txt`がありません。

Hugoにおける`robots.txt`の扱いについて、以下のページに書かれています。

{{< linkcard "https://gohugo.io/templates/robots/" >}}

ひとまず、`hugo.toml`に対して`enableRobotsTXT = true`と書き込むことで全てのクローラを許可するテンプレート(`User-agent: *`)が適用されます。

テンプレートの`hugo.toml`に書いても反映されないみたいなので注意です。