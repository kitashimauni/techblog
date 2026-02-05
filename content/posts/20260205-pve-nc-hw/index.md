+++
aliases = []
date = 2026-02-05T03:16:23+09:00
draft = false
summary = '動画像を扱うのに便利なMemoriesで動画を再生する際にHW Accelerationを有効にする方法を書きます'
tags = ['Proxmox', 'Nextcloud']
title = 'Proxmox上のNextcloudにMemoriesを導入してHW Accelerationを使う'
url_title = 'pve-nc-hw'
+++

今回はProxmox上に立てられたNextcloudのMemoriesで、HW Accelerationを有効にする方法を記します。

HW Accelerationを有効にすることで、Memories上で動画を再生する際のCPU負荷を大きく軽減できます。

{{< details summary="Memoriesとは" >}}
NextcloudにはMemoriesというアプリケーションがあり、このアプリケーションでは動画のTranscodingを有効にできます。

Nextcloudで動画を再生する際、何もしていないとそのままの画質でしか再生できませんが、Transcodingすることで低い画質で再生することも可能になります。

これによって、通信環境がよくない場所でも低画質でスムーズに再生できます。

また、大量の画像を扱うのにも適していて、工夫して表示してくれるので大量の画像を読み込んでも重くならないという利点があります。

一方で、Transcodingを有効にすると動画再生時にCPUに対する負荷が非常に大きくなってしまいます。
{{< /details >}}

## 前提条件
前提は以下のとおりです。

- Proxmox上のlxcとしてNextcloudが立てられている
- Memoriesをインストール済み
- CPUがハードウェアアクセラレーションに対応している
  - 内臓グラフィックではないGPUでのハードウェアアクセラレーションの説明はありません

## Proxmox上での準備
まずはProxmox上で作業を行います。

初めに、`render`のGIDを以下のコマンドで確認しておきます。

```bash
ls -n /dev/dri/renderD128
```

今回は以下のようになりました。

```txt
crw-rw---- 1 0 104 226, 128 Nov 27 22:02 /dev/dri/renderD128
```

GIDが `104` になっています。

GIDをコンテナに渡せるように、以下のように設定を加えます。

```txt {name="/etc/subgid"}
root:104:1
```

次に、lxcがGPUにアクセスできるようにするため、以下を設定ファイルに追記します。

**上記で確認したGIDを基に計算して書き込む必要があるため、注意してください**

```txt {name="/etc/pve/lxc/[lxcの番号].conf"}
lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
lxc.mount.entry: /dev/dri/card0 dev/dri/card0 none bind,optional,create=file
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file
lxc.idmap: u 0 100000 65536
lxc.idmap: g 0 100000 {GID}
lxc.idmap: g {GID} {GID} 1
lxc.idmap: g {GID + 1} 100{GID + 1} {65536 - (GID + 1)}
```

例: GIDが `104` のとき
```txt
lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
lxc.mount.entry: /dev/dri/card0 dev/dri/card0 none bind,optional,create=file
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file
lxc.idmap: u 0 100000 65536
lxc.idmap: g 0 100000 104
lxc.idmap: g 104 104 1
lxc.idmap: g 105 100105 65431
```

{{< details summary="設定項目の詳細な説明" >}}
最初の2行はlxcがGPUにアクセスできるように権限を与えています。
```txt
lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
```

次の2行はlxcにデバイスをマウントしてアクセスできるようにしています。
```txt
lxc.mount.entry: /dev/dri/card0 dev/dri/card0 none bind,optional,create=file
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file
```

最後の4行は、lxc内のIDのマッピングを行っています。これをしないと、権限が足りないために動きません。

通常は100000にIDを足すようにマッピングされていますが、GPUのみ通常のマッピングにして解決しています。
```txt
lxc.idmap: u 0 100000 65536
lxc.idmap: g 0 100000 {GID}
lxc.idmap: g {GID} {GID} 1
lxc.idmap: g {GID + 1} 100{GID + 1} {65536 - (GID + 1)}
```
{{< /details >}}

最後に、Nextcloudのlxcを停止 → 再開して設定の変更を反映させます。

## Nextcloud上での設定
正しくGPUを認識できている下記コマンドで確認します。

```bash
ls -ln /dev/dri/renderD128
```

以下のように、最初にProxmox上で確認したGIDが入っていれば問題ありません。

```txt
crw-rw---- 1 65534 104 226, 128 Nov 27 13:02 /dev/dri/renderD128
```

VA-APIを使えるようにするため、ドライバをインストールします。

CPUによってインストールするドライバが異なるので注意してください。

### AMD(Ryzen等)の場合
```bash
sudo apt update
sudo apt install mesa-va-drivers libva-drm2 libva2
```

### Intelの場合
```bash
sudo apt update
sudo apt install intel-media-va-driver-non-free libva-drm2 libva2
```

NextcloudがGPUにアクセスできるようにするため、権限を追加します。

```bash
usermod -aG render www-data
```

{{< details summary="詳しく確認する" >}}
設定が正しく反映されているか、以下のコマンドで詳細なステータスを確認できます。

```bash
# vainfoのインストール
sudo apt update && sudo apt install vainfo

# www-dataユーザーとして実行して権限も含めてチェック
sudo -u www-data vainfo --display drm --device /dev/dri/renderD128
```

問題がなければ以下のように情報が表示されます。
```txt
libva info: VA-API version 1.17.0
libva info: Trying to open /usr/lib/x86_64-linux-gnu/dri/radeonsi_drv_video.so
libva info: Found init function __vaDriverInit_1_17
Failed to create /var/www/.cache for shader cache (Permission denied)---disabling.
libva info: va_openDriver() returns 0
vainfo: VA-API version: 1.17 (libva 2.12.0)
vainfo: Driver version: Mesa Gallium driver 22.3.6 for AMD Radeon Graphics (renoir, LLVM 15.0.6, DRM 3.57, 6.8.12-11-pve)
vainfo: Supported profile and entrypoints
      VAProfileMPEG2Simple            : VAEntrypointVLD
      VAProfileMPEG2Main              : VAEntrypointVLD
      VAProfileVC1Simple              : VAEntrypointVLD
      VAProfileVC1Main                : VAEntrypointVLD
      VAProfileVC1Advanced            : VAEntrypointVLD
      VAProfileH264ConstrainedBaseline: VAEntrypointVLD
      VAProfileH264ConstrainedBaseline: VAEntrypointEncSlice
      VAProfileH264Main               : VAEntrypointVLD
      VAProfileH264Main               : VAEntrypointEncSlice
      VAProfileH264High               : VAEntrypointVLD
      VAProfileH264High               : VAEntrypointEncSlice
      VAProfileHEVCMain               : VAEntrypointVLD
      VAProfileHEVCMain               : VAEntrypointEncSlice
      VAProfileHEVCMain10             : VAEntrypointVLD
      VAProfileHEVCMain10             : VAEntrypointEncSlice
      VAProfileJPEGBaseline           : VAEntrypointVLD
      VAProfileVP9Profile0            : VAEntrypointVLD
      VAProfileVP9Profile2            : VAEntrypointVLD
      VAProfileNone                   : VAEntrypointVideoProc
```
{{< /details >}}

Nextcloudの管理画面からMemoriesを選択し、以下のように設定を変更します。
- Video Streaming > Enable Transcoding を有効にする (`ffmpeg` と `ffprobe` を必要に応じてインストールしてください)
- HW Acceleration > Enable acceleration with VA-API を有効にする (`VA-API device (/dev/dri/renderD128) is readable` と表示されていればOK)

これで、ハードウェアアクセラレーションが有効になりました。CPUの負荷が大きく低下するはずです。

## おわりに
NASがわりに使っているNextcloudですが、少し使いやすくなりました。
