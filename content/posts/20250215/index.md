+++
title = 'WSLにArchLinuxを入れてみる'
date = '2025-02-15T00:29:15+09:00'
lastmod = '2025-04-27T00:29:15+09:00'
draft = false
summary = 'WSLにArchLinuxを入れる記事'
tags = [ 'WSL', 'Arch' ]
+++

ArchLinuxをWSLに入れてみようと思います。

## ArchLinuxをダウンロードしてWSLに登録する

> [!CAUTION]
> この方法はWSLが公式に提供するArchLinuxを使用しない方法です。
> 
> 2025年4月にWSLの下記コマンドだけでArchLinuxを入れることができるようになりました。
> ```bash
> wsl --list -o # 使用可能なディストリビューション一覧
> wsl --install archlinux --name {名前} # ArchLinuxをインストール
> wsl -d {名前} # ディストリビューションを指定して起動
> ```

[ArchWiki](https://wiki.archlinux.jp/index.php/WSL_%E3%81%AB%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB)に一応書かれてはいるものの、情報が古いのであまり参考にならなそうです。

`wsl --help`を実行すると、`--import`オプションでtarファイルを新しいディストリビューションとしてインポートできるようなのでArchLinuxのブートストラップをもってくればよさそうです。

ArchLinuxの[ダウンロードページ](https://archlinux.org/download/#http-downloads)で適当なミラーサイトを探してそこからダウンロードします。

最初はWindowsでダウンロードしようとしたのですが、Windowsはデフォルトではファイル名の大文字と小文字を区別しないので解凍した時に色々と面倒なことになります。そこで、すでにWSLに作ってあるUbuntu内で作業します。

ダウンロードは以下コマンドです。リンクアドレスは使用するミラーサイト名にし、バージョンも適宜変更してください。

```bash
wget https://mirror.aria-on-the-planet.es/archlinux/iso/2025.02.01/archlinux-bootstrap-2025.02.01-x86_64.tar.zst
```

一応チェックサムを確認しておきます。以下のコマンドでチェックサムをダウンロードして確認します。これもバージョンごとにリンクが違うので気を付けましょう。`b2sum`では`--ignore-missing`を指定して存在しないファイルは無視しています。`OK`と表示されれば問題ありません。
```bash
wget https://archlinux.org/iso/2025.02.01/b2sums.txt
b2sum -c b2sums.txt --ignore-missing
```

次に`tar`コマンドで解凍します。ファイル名はダウンロードした際の名前です。

```bash
sudo apt install zstd # tarコマンドでzstdが無いと言われる場合
tar -Izstd -xf archlinux-bootstrap-2025.02.01-x86_64.tar.zst
```

解凍すると`root.x86_64`と`pkglist.x86_64.txt`が出てきます。必要なのは`root.x86_64`なのでこれを再びtarで圧縮します。その後、/mnt以下のWindowsに移動します。

{{< details summary="補足">}}
環境によるかもしれませんが、圧縮の際に特定のファイルに対するアクセス権が無いことで正常に処理できなかったので、事前に`sudo chmod 777 root.x86_64 -R`を実行しました。

圧縮の際は、解凍後にディレクトリ(`root.x86_64`)の中身が直接展開されるように圧縮しないと、起動しようとしたときにエラーが出て起動できないので注意です。
{{< /details >}}

このとき、圧縮前に`root.x86_64`の`/etc/pacman.d/mirrorlist`で使用するサーバーのコメントアウトを解除しておくといいと思います。

```bash
tar -Izstd -cf root.x86_64.tar.zst -C root.x86_64 .
mv root.x86_64.tar.zst {Windows上の適当な場所}/
```

これで用意は整いました。以下のコマンドでWSLにArchLinuxをインポートします。`C:\wsl\Arch`はVHDXを置く場所なので好きな場所を指定してください。
```powershell
wsl --import ArchLinux C:\wsl\Arch {root.x86_64.tar.zstを置いたWindows上のパス}
```

`-d`オプションでArchLinuxを指定して起動します。
```powershell
wsl -d ArchLinux
```

## ArchLinuxのセットアップ
### pacman
圧縮前にmirrorlistを変更しなかった場合、ここで`/etc/pacman.d/mirrorlist`に変更を加えなければなりません。

~~しかし、初期状態ではnanoやvimが使えないので`echo`コマンドの出力をリダイレクトして追記するという原始的な手法を取る必要があります。`cat`コマンドで中身を確認し、適当なサーバーを書き込みます。~~

普通にWindowsのエクスプローラーからメモ帳で開いて編集できます。便利。
{{< details summary="エディタを全く使わないで書き込む">}}
```bash
cd /etc/pacman.d/
echo "Server = http://mirror.aria-on-the-planet.es/archlinux/\$repo/os/\$arch" >> mirrorlist
```
{{< /details >}}

適当なサーバーの子マンとアウトを外してあればpacmanのリポジトリの同期ができます。以下のコマンドを実行します。

```bash
pacman -Syy # リポジトリの同期
pacman-key --init # キーリングの初期化
pacman-key --populate archlinux # オフィシャルパッケージ開発者の鍵を登録しておく
pacman -S reflector # 自動で速度が速い順にサーバーを並び変えるpythonスクリプト
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist_backup # バックアップ
reflector --country Japan --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
```

pacmanの設定を少し変えておきます。この変更により、パッケージを並列でダウンロードできるようになります。
```bash
pacman -S vim # vimをインストール
vim /etc/pacman.conf # [options]のParallelDownloads = 5のコメントアウトを外す
```

### シェルとユーザーの追加

ひとまずZshを使うのでpacmanでインストールします。加えてロケールとタイムゾーンの設定もしておきます。これで日本語も正しく表示できるようになるはずです。
```bash
pacman -S zsh
vim /etc/locale.gen # en_US.UTF-8 UTF-8 のコメントアウトを外す
locale-gen # デフォルトでlocaleがen_US.UTF-8になっているのでとりあえずこれをしておけばよい
ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime # タイムゾーンの設定
hwclock --systohc 
```

新しくユーザーを作ります。

```bash
passwd # rootユーザーのパスワード設定
useradd -m -G wheel -s /bin/zsh {ユーザ名} # ユーザーの作成
passwd {ユーザ名} # 新しく追加したユーザーのパスワード設定
pacman -S sudo # sudoのインストール
EDITOR=vim visudo # /etc/sudoeresの %wheel ALL=(ALL:ALL) ALL のコメントアウトを外す
```

起動時のデフォルトのユーザーに先ほど作成したユーザーを指定します。`/etc/wsl.conf`に以下を書き込みます。ついでにsystemdを有効化する設定も書き込んでおきます。
```txt
[boot]
systemd=true

[user]
default={ユーザー名}
```

これで一度WSLをシャットダウンし、再起動すると`/etc/wsl.conf`で設定したユーザーでログインされます。また、ログイン時のシェルにZshを指定した場合は、Zshの初回設定画面が表示されるのでお好みで設定しましょう。

(最初に`wsl.conf`を作ったときは再起動しても設定が反映されなかったので、`wsl.conf`を作り直したら設定が反映されました。誤字はしてなかったはずなので原因はわかりません…)

### 環境構築をする
とりあえずの環境構築をしてみます。まずはC・C++から。
```zsh
sudo pacman -Ss gcc # 検索
sudo pacman -S gcc # インストール
```

簡単ですね。次にPythonです。とりあえず`uv`を入れておきます。

```zsh
sudo pacman -Ss uv # 検索
sudo pacman -S uv # インストール
```

これも簡単です。あとは`git`ですね。
```zsh
sudo pacman -Ss git # 検索
sudo pacman -S git github-cli # インストール
```

## おわりに
最低限はできたのでここまでにしておきます。壊しても問題ない環境なので気が楽でいいですね。

シェルの見た目をリッチにしたりNeovimを入れて遊んだりしたいです。
