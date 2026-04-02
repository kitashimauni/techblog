+++
aliases = []
date = 2026-04-01T15:35:48+09:00
draft = true
summary = 'DBをセルフホストしてObsidianのセットアップをします'
tags = ['Obsidian', 'サーバー']
title = 'self-hostedのDBでObsidianをセットアップする'
url_title = 'obsidian-setup'
+++

Obsidian用のDBをセルフホストしたので備忘録的に書いておきます。

# 前提
前提は以下の通りです。
- Proxmox上でのホスト
  - Proxmoxである必要はないです
  - Ubuntu等であれば問題なくホスト可能なはずです
- Tailscaleを使用
  - Tailscaleを使わない場合は自分でネットワークの設定をする必要があります
- ドメインを持っている
  - この記事ではCloudflareで管理しているドメインを使用します
- 何らかの方法でTailscaleのIPアドレスがDNS解決可能
  - 私はProxmox上にDNSを立てて運用していますが、Tailscaleの機能だけでDNS解決させることも可能です

# 前準備
まずはProxmox上にベースとなるlxcを立てます。

ベースイメージは `ubuntu-24.04-standard_24.04-2_amd64.tar.zst` にしました。Proxmoxのテンプレートにあります。

Proxmox上で作業している場合、lxc上でTailscaleを使うためProxmoxホストの `/etc/pve/lxc/{ID}.conf` に以下を追記しておきます。

(起動後に書き込んだ場合はlxcを再起動する必要があります)

```txt {name="/etc/pve/lxc/ID.conf"}
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
```

以下コマンドで必要なものをインストールします。

{{< details summary="インストール用コマンド" >}}

## 最低限必要なものをインストール

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
```

## Dockerインストール

```bash
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg

# 公式GPGキーを追加
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# リポジトリをAPTソースに追加
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# インストール
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## Tailscaleインストール

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

ログインも済ませておきます。

```bash
tailscale up
```

## DNSの設定をする
Tailscale上でのIPアドレスをDNS解決できるようにしておきます。

{{< /details >}}

この後はrootでないユーザーで作業します。

{{< details summary="ユーザーの作成" >}}

下記コマンドでユーザーを作成した後、exitしてログインしなおせばよいです。(`user` という名前のユーザーが作成されます)

```bash
sudo useradd -m -s /bin/bash -G docker user
sudo passwd user
```

{{< /details >}}

# DBの導入
さっそくDBを導入します。

CouchDBを立てるための `docker-compose.yml` を用意します。

```yml {name="docker-compose.yml"}                                                                                      
services:
  obsidian-db:
    image: couchdb:latest
    container_name: obsidian-db
    restart: always
    expose: 
      - "5984"
    environment:    
      - COUCHDB_USER=admin
      - COUCHDB_PASSWORD={適当なパスワード}
    volumes:
      - ./couchdb-data:/opt/couchdb/data

  nginx-proxy:
    image: 'jc21/nginx-proxy-manager:latest'
    container_name: nginx-proxy-manager
    restart: always
    ports:
      - '80:80'
      - '443:443'
      - '81:81'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
```

この後は [過去のページ](https://tech.n-island.dev/posts/20260224-tailscale-web-service/) の要領で接続できるようにセットアップします。

ドメインでアクセスできるようになったら、`https://{ドメイン}/_utils/#setup` にアクセスします。

ここで `docker-compose.yml` に書いたアカウント名とパスワードでログインできればOKです。

CORSの設定もしておきます。画面左側の歯車マークをクリックして『CORS』で『Enable』を選択、『All domains』を許可しておきます。

# Obsidianアプリから確認する
ObsidianのアプリからDBに接続してみます。

コミュニティプラグインから `Self-hosted LiveSync` を導入します。

モーダルが出てくるので以下の順で設定します。

- "I am setting this up for the first time"
- "Enter the server information manually"
- "End-to-End Encryption"
  - "End-to-End Encryption" にチェック
  - Passwordを入力
- "CouchDB"
- "CouchDB Configuration"
  - URL, Username, Passwordを入力

これで成功すれば初期設定は完了です。

# 動作確認
同期設定を『LiveSync』にしておきます。

『イベント時』になっていると同期頻度が低くなってしまいます。

# おわりに
無事にObsidianのセットアップができました。スマホとPCで同期できていることを確認しました。

プラグインを入れると色々と便利になるようなので試してみたいです。
