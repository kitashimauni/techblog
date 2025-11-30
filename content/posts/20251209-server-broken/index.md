+++
title = 'サーバーが壊れて修理した話'
date = '2025-12-09T00:00:00+09:00'
draft = false
summary = '自宅サーバーが壊れました'
tags = ['Proxmox', 'Linux', 'サーバー']
+++

この記事は農工大アドベントカレンダー2025の9日目の記事です。

{{< linkcard "https://qiita.com/advent-calendar/2025/tuat" >}}

**自宅サーバーが壊れました**

故障したサーバーの構成は以下のとおりです。

- **CPU**: AMD Ryzen 5 5500GT with Radeon Graphics
- **メモリ**: 16GB × 2 (Crucial CT2K16G4DFRA32A) 
- **ストレージ**: SSD(Apacer AS2280Q4L 1TB) × 1, HDD(WD Red 4TB) × 2
- **電源**: ANTEC CSK Bronze 750H
- **マザーボード**: ASUS PRIME B550M-A WIFI II

## 異常発生
以下の現象が発生しました。

- 突如Proxmoxへの接続が途切れる
- サーバーを確認したところ、**ケースファンやCPUファンは正常に回っている**
- **マザーボードのデバッグLEDは点灯していない**
- **SSDのアクセスランプは点灯していない**

外見上は問題なく動作しているのですが、Proxmoxに接続できいない状態になっていました。

100日以上連続で問題なく稼働していたため、少し嫌な感じです。

ここからは、試したことを順に説明していきます。

## キーボードとモニターを接続する
念のためキーバードとモニターを接続して本当にOSが落ちているか確認します。

モニターには何も出力されませんでした。

キーボードで以下の入力をして再起動を試みます。

- Alt + PrintScreen (SysRq) + R (キーボードの制御を取り戻す)
- Alt + PrintScreen + E (プロセスを終了)
- Alt + PrintScreen + I (プロセスを強制終了)
- Alt + PrintScreen + S (ディスクを同期・保存)
- Alt + PrintScreen + U (ディスクを読み取り専用でマウント)
- Alt + PrintScreen + B (再起動)

この手順はシステムがフリーズした時に安全に再起動するためのもので、「Raising Elephants Is So Utterly Boring（象を育てるのは退屈だ）」と覚えるのがいいらしいです。

この手順を試しましたが**再起動された様子はなく、モニターに映像が出力されることはありませんでした**。

## 強制再起動をかける
OSからの再起動はできなさそうだったので、強制再起動をかけます(読み書き中の場合、ストレージに悪影響を与えるのであまりやりたくはないです)。

ケースの電源ボタンを長押しして電源を落としました。

電源ユニットの主電源を落とし、電源ケーブルやLANケーブルなど接続されているものを抜いたうえで、ケースの電源ボタンを何度か押して残っている電気を抜いておきます。

数分後、再度電源などを接続して電源をいれました。

**結果としては、ファンは回るもののモニターに何も出力されませんでした**。

これらの結果から、BIOSの起動すらできていないことがわかりました。

## 最小構成での起動を試みる
再起動で問題が解決しなかったため、まずは最小構成でのBIOS起動を目標に原因の特定を目指します。

ストレージ類とメモリ1枚をマザーボードから取り外して起動すると、無事にBIOSが起動しました。

その後、メモリとストレージ類を戻していくと、無事にProxmoxの起動まで確認できました。

## Proxmoxのログを確認する
以下のコマンドで1回前の起動時のログの末尾を確認します。`-b -1` で1回前、`-e` でログの末尾を表します。

```bash
journalctl -b -1 -e
```

このコマンドを実行した結果、Proxmoxが落ちる前のログは以下のようになっていることがわかりました。

```text
Nov 21 15:37:07 pve systemd[1]: Starting apt-daily.service - Daily apt download activities...
Nov 21 15:37:07 pve systemd[1]: apt-daily.service: Deactivated successfully.
Nov 21 15:37:07 pve systemd[1]: Finished apt-daily.service - Daily apt download activities.
Nov 21 15:48:49 pve snapd[2768209]: storehelpers.go:916: cannot refresh: snap has no updates available: "certbot", "certbot-dns-cloudflare", "core24", "snapd"
Nov 21 15:55:07 pve systemd[1]: Starting snap.certbot.renew.service - Service for snap application certbot.renew...
Nov 21 15:55:07 pve systemd[1]: snap.certbot.renew.service: Deactivated successfully.
Nov 21 15:55:07 pve systemd[1]: Finished snap.certbot.renew.service - Service for snap application certbot.renew.
Nov 21 15:57:35 pve smartd[816]: Device: /dev/sda [SAT], SMART Usage Attribute: 194 Temperature_Celsius changed from 118 to 119
Nov 21 16:00:36 pve tailscaled[3161648]: c2n: GET /update received
Nov 21 16:00:36 pve tailscaled[3161648]: control: controlhttp: forcing port 443 dial due to recent noise dial
Nov 21 16:17:01 pve CRON[535374]: pam_unix(cron:session): session opened for user root(uid=0) by (uid=0)
Nov 21 16:17:01 pve CRON[535375]: (root) CMD (cd / && run-parts --report /etc/cron.hourly)
Nov 21 16:17:01 pve CRON[535374]: pam_unix(cron:session): session closed for user root
Nov 21 16:57:35 pve smartd[816]: Device: /dev/sdb [SAT], SMART Usage Attribute: 194 Temperature_Celsius changed from 118 to 119
Nov 21 17:17:01 pve CRON[553225]: pam_unix(cron:session): session opened for user root(uid=0) by (uid=0)
Nov 21 17:17:01 pve CRON[553226]: (root) CMD (cd / && run-parts --report /etc/cron.hourly)
Nov 21 17:17:01 pve CRON[553225]: pam_unix(cron:session): session closed for user root
Nov 21 17:27:35 pve smartd[816]: Device: /dev/sda [SAT], SMART Usage Attribute: 194 Temperature_Celsius changed from 119 to 120
```

エラーログが何も残されていません。OSがログを残すまでもなく落ちてしまったことがうかがえます。

## ストレージのヘルスチェックを行う
強制再起動をかけてしまったので、ヘルスチェックを行います。

まずは以下のコマンドでSSDに問題がないか確認します。

```bash
smartctl -a /dev/nvme0n1
```

出力は以下の通りです。強制再起動をかけたので`Unsafe Shutdowns`の値が増加していますが、`Critical Warning`や`Media and Data Integrity Errors`に変化はなく、特に問題はなさそうです。

```text
smartctl 7.3 2022-02-28 r5338 [x86_64-linux-6.8.12-11-pve] (local build)
Copyright (C) 2002-22, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Model Number:                       Apacer AS2280Q4L 1TB
Serial Number:                      ***
Firmware Version:                   X0108A0
PCI Vendor/Subsystem ID:            0x126f
IEEE OUI Identifier:                0x486834
Total NVM Capacity:                 1,024,209,543,168 [1.02 TB]
Unallocated NVM Capacity:           0
Controller ID:                      1
NVMe Version:                       1.4
Number of Namespaces:               1
Namespace 1 Size/Capacity:          1,024,209,543,168 [1.02 TB]
Namespace 1 Formatted LBA Size:     512
Namespace 1 IEEE EUI-64:            ***
Local Time is:                      Sun Nov 23 01:50:49 2025 JST
Firmware Updates (0x16):            3 Slots, no Reset required
Optional Admin Commands (0x0017):   Security Format Frmw_DL Self_Test
Optional NVM Commands (0x00df):     Comp Wr_Unc DS_Mngmt Wr_Zero Sav/Sel_Feat Timestmp Verify
Log Page Attributes (0x1e):         Cmd_Eff_Lg Ext_Get_Lg Telmtry_Lg Pers_Ev_Lg
Maximum Data Transfer Size:         64 Pages
Warning  Comp. Temp. Threshold:     86 Celsius
Critical Comp. Temp. Threshold:     93 Celsius

Supported Power States
St Op     Max   Active     Idle   RL RT WL WT  Ent_Lat  Ex_Lat
 0 +   4.5000W       -        -    0  0  0  0        0       0
 1 +   2.4000W       -        -    1  1  1  1        0       0
 2 +   0.6000W       -        -    2  2  2  2        0       0
 3 -   0.0250W       -        -    3  3  3  3     5000    5000
 4 -   0.0040W       -        -    4  4  4  4     5000   25000

Supported LBA Sizes (NSID 0x1)
Id Fmt  Data  Metadt  Rel_Perf
 0 +     512       0         0

=== START OF SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED

SMART/Health Information (NVMe Log 0x02)
Critical Warning:                   0x00
Temperature:                        37 Celsius
Available Spare:                    100%
Available Spare Threshold:          10%
Percentage Used:                    0%
Data Units Read:                    4,963,713 [2.54 TB]
Data Units Written:                 6,091,478 [3.11 TB]
Host Read Commands:                 41,397,752
Host Write Commands:                96,024,738
Controller Busy Time:               17,842
Power Cycles:                       13
Power On Hours:                     4,404
Unsafe Shutdowns:                   9
Media and Data Integrity Errors:    0
Error Information Log Entries:      0
Warning  Comp. Temperature Time:    0
Critical Comp. Temperature Time:    0
Temperature Sensor 1:               37 Celsius
Temperature Sensor 2:               48 Celsius

Error Information (NVMe Log 0x01, 16 of 256 entries)
No Errors Logged
```

次に、以下のコマンドでZFSプールに問題がないか確認します。

```bash
zpool status -x
```

出力は以下のとおりで、こちらも問題なさそうです。

```text
all pools are healthy
```

## 復旧完了
この時点で、ログが突如として途切れていていて、最小構成にして組みなおしたら問題なく動作したことから、今回の問題の原因は **SSDの接触不良** と結論付けました。

初夏にサーバーを組んでから半年程度、初めての経験だったため焦りましたが直ってめでたしめでたし。

と思っていましたが…

## 容態急変【FULL】
これまでの復旧作業で元の状態に戻ったのが11/23の01:28です

```text
Nov 23 01:28:30 pve kernel: Linux version 6.8.12-11-pve (build@proxmox) (gcc (Debian 12.2.0-14+deb12u1) 12.2.0, GNU ld (GNU Binutils for Debian) 2.40)
```

その翌日、Proxmoxにアクセスしようとしたところ、また繋がらなくなっていることに気づきました。

サーバーをみると、**同じ現象が発生しています**。

どうやら **これまでの一連の問題はSSDの接触不良ではなかった** ようです。

## 原因の特定
強制再起動を試しましたがやはりBIOSすら起動しません。

ここで、1つの可能性が非常に有力となります。

それは **電源ユニットの故障**。

これまで見てきたように、Proxmoxは落ちる前に何もログを残していませんでした。

これは、Proxmoxがログを残す猶予を与えられることなく落ちていることを示しています。

GeminiやChatGPTに聞くと電源ユニットが怪しいと答えました。同じような症状を調べてもあまり有力な記事は見つかりませんでした。

## 電源ユニットの交換
まずは電源ユニットを交換して様子を見ることにしました。ちょうどAmazonでブラックフライデーをやっていたのでCORSAIRのGold電源を購入。

{{< linkcard "https://www.amazon.co.jp/dp/B0D46M8655" >}}

(アフィリエイトリンクではありません)

到着した電源ユニットをさっそく交換して、電源ボタンを押すとちゃんと起動しました。一安心。

再びログを除いてみると、最後のログは11/27の22時台で止まっており、24時間もたずに落ちていたようです。

ひとまずは様子見です。

これでダメな場合は以下の手順で検証を行う予定です。CMOSクリアなどは電源ユニットの交換前に確かめておいてもよかったかもしれません。

1. マザーボードのボタン電池の交換
2. メモリの整合性チェック

## おわりに
長らく問題なく稼働していたサーバーが壊れるという一大事でした。

電源ユニットが問題であった可能性は高いですが、Bronze電源とはいえ半年前にサーバーを組むために新品で購入したものなので少し壊れるのが早い気もします(逆に初期不良というには遅い)。

電源ユニットが新しくなりましたが、非常に静音でうれしいです。

インフラの運用や保守がいかに大事か思い直す事件でした。

