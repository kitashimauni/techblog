+++
title = 'stable-diffusion-webuiを動かしてみる'
date = '2025-03-02T14:13:09+09:00'
draft = false
summary = 'stable-diffusion-webuiを簡単に動かします'
tags = [ '生成AI' ]
+++

stable-diffusion-webuiを動かしてみます。

{{< linkcard "https://github.com/AUTOMATIC1111/stable-diffusion-webui" >}}

## 環境構築
面倒な環境構築はしたくないので、簡単な方法でやっていきます。環境は以下の通りですが、GPUさえ動けばどこでも動くと思います。

- Windows11
- Nvidia GeForce RTX4070ti

まずはGitとUVを入れましょう。既に入っている人は飛ばしてください。

Gitはリポジトリのクローンに、UVはPython環境の作成に使います。PowerShellを開いてWingetでインストールできます。

```powershell
winget install Git.Git
winget install astral-sh.uv
```

インストールが終わったら、リポジトリをクローンします。クローンしたい場所で以下のコマンドを実行してください。

```powershell
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git
```

その後、クローンした場所に移動してPythonの環境を作ります。
```powershell
cd .\stable-diffusion-webui\ # 移動
uv venv -p 3.10.6 # 環境の作成
.venv\Scripts\activate # 仮想環境の有効化
uv pip install pip # pipのインストール
```

そして、以下のコマンドを実行するとモデルのダウンロードが行われ、それが終了するとブラウザが立ち上がって環境の構築は完了です。

```powershell
./webui-user.bat
```

{{< figure src="./src/webui.png" alt="起動した様子" >}}

## 別のモデルを入れてみる
デフォルトで入ってくるモデルはあまり性能が良くなさそうなので、イラスト生成用に追加学習されたstable-diffusionベースのモデルであるAnimePastelDreamを入れてみます。下記のページでダウンロードボタンを押せばダウンロードできます。

{{< linkcard "https://civitai.com/models/23521/anime-pastel-dream" >}}

ダウンロードした`.safetensor`を`models/Stable-diffusion`フォルダに入れます。この状態で左上のリロードボタンを押すと、先ほど入れたAnimePasteDreamが選択できるようになっているので選択します。

## 画像を生成してみる
画像生成時のパラメータについて簡単に説明します(著者も詳しくはありません)。

モデルによっては推奨されるパラメータが書かれているようなのでその場合はそれに従うとよさそうです。

### パラメータ
#### Prompt
Promptは画像を生成する際の指示文です。ここに生成したい画像の特徴などを書き込みます。

#### Negative prompt
Negative promptは画像を生成する際の指示文ですが、生成してほしくない画像の特徴などを書き込みます。

#### Sampling method
Sampling methodは画像生成において、どのようにサンプリングするかを決めるパラメータです。選択肢が色々ありますが、DDIMなどがよいようです。

Sampling methodによって生成される画像の作風が異なることがあるので、色々試してみるといいと思います。

#### Sampling steps
Sampling stepsはSamplingを何回行うかのパラメータです。この値が大きいほど明瞭な画像が得られますが、生成にかかる時間も比例して長くなり、大きくしすぎても意味がないこともあるので、20~40程度にとどめておくのがよさそうです。

#### Width・Hight
Width・Hightは生成する画像のサイズです。サイズが大きいほど生成にかかる時間も長くなります。

#### Batch count・Batch size
Batch sizeは一度に(1Batchあたり)何枚の画像を処理するかという値です。また、Batch countはBatch処理を何回行うかという値です。

結果として、Batch count × Batch size枚の画像が生成されることになります。

Batch sizeを大きくすると必要なGPUメモリ量が大きくなるので注意が必要です。

#### CFG Scale
CFG Scaleは画像を生成する際にどれだけプロンプトに忠実に従うかを決める値です。この値が大きいほどプロンプトに忠実な画像を生成するようになります。

大きければいいというものではないので、様々な値を試して決めるのがよさそうです。

### 画像を生成する
画像生成のプロンプトに詳しくはないので、[この画像](https://civitai.com/images/316170)の生成に用いられたプロンプトをそのまま使って1枚生成してみます。

PromptとNegative Promptをコピペして、Generateボタンを押します。512×512の画像を1枚生成するだけであれば数秒で終了し、以下の画像が出力されました。やはり手の描画が苦手みたいですが、そこに目をつぶれば悪くないのではないでしょうか。
{{< figure src="./src/generated.png" alt="生成された画像" width=50% >}}

PromptかNegative Promptで変な出力がされないように指示を与えるのが重要みたいです。この部分は何を生成するにしても使いまわせそうですね。

単にテキストから画像を生成する以外にもいろいろできそうなのでもう少し遊んでみたいです。