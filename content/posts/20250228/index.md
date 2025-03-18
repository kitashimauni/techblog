+++
title = 'Unityのプロジェクト作成方法'
date = '2025-02-28T21:18:19+09:00'
lastmod = '2025-03-18T17:18:19+09:00'
draft = false
summary = 'Unityでプロジェクトを作成する際の手順'
tags = ['Unity']
+++

Unityのプログラムを作る手順について、備忘録的に書きます。

前提
- Unity Hubがインストールされている(Personalライセンス認証済み)
- Gitがインストールされている
- GitHubのアカウントを作成済み

## Unity Hubでプロジェクトを作る
最初にUnity Hubでプロジェクトを作成します。

### 最新のUnity Editorをインストールする
プロジェクト作成時点での最新バージョンを使うのが好ましいので、初めに最新バージョンのエディタをインストールします。

左側のInstallsを選択して右上の"Install Editor"をクリックします。

{{< figure src="./src/unity_installs_1.png" alt="Installsを開く">}}

そうすると最近のリリース一覧が表示されます。基本的には"Recommended version"と書かれているものを選択すれば問題ありません。

ここでは、Unity6(6000.0.40.f1)を選択します。このプロジェクトの開発に参加する人は、今後このバージョンを使って開発を行うことになります。

{{< figure src="./src/unity_installs_2.png" alt="バージョンの選択画面" >}}

これをクリックすると、"Add modules"と表示されます。基本的には何も追加しないで問題ありませんし、必要になれば後から追加することもできるのでそのままInstallボタンを押します。

{{< figure src="./src/unity_installs_3.png" alt="Add modules" >}}

インストールには時間がかかるので気長に待ちましょう。

### Unityのプロジェクトを作る
Unityのプロジェクトを作成します。左側のProjectsを選択して右上の"New Project"をクリックします。

ここで、テンプレートを選択してプロジェクト名、保存場所を入力します。

テンプレートは3Dゲームであれば"Universal 3D"を選べば問題ないと思います。また、"Connect to Unity Cloud"はオフにしておいたほうが平和かもしれません。

{{< figure src="./src/create_unity_project.png" alt="プロジェクト作成画面" >}}

入力が済んだら"Create project"をクリックしましょう。初回は時間がかかりますがエディタが立ち上がります。

起動を待つ間にこの後のGit関連の作業をしておくと効率的かもしれません。

## GitHubリポジトリの作成
### .gitignoreを作る
`.gitignore`を作ります。これを簡単に作るツールとして、[gitignore.io](https://www.toptal.com/developers/gitignore)というものがあります。

{{< figure src="./src/gitignore_io.png" alt="gitignore.io" >}}

入力欄に、"Unity"・"JetBrains"・"macOS"を入力してCreateボタンを押します。

すると、以下のように`.gitignore`に書くべき内容が出力されるので、プロジェクトディレクトリの直下に`.gitignore`を作ってコピペします。

{{< figure src="./src/gitignore_io_result.png" alt="gitignore.ioで生成した結果" >}}

"JetBrains"と"macOS"は開発環境における不要なファイルを除く目的で追加しています。

このとき、間違っても"Visual Studio"を追加してはいけません。これをすると、Unityの`.meta`ファイルがignoreされて大変なことになります。

### .gitattributesを作る
`.gitattributes`を作ります。これは、開発環境ごとの改行コードの違いを統一するために使います。

改行コードが統一されていないと、見た目上の差分は無いのに変更が加えられたことになってややこしくなります。

プロジェクトディレクトリの直下に以下の内容の`.gitattributes`を作ります。

```text {name=".gitattributes"}
* text=auto

# Define macros (only works in top-level gitattributes files)
[attr]unity-json        eol=lf linguist-language=json
[attr]unity-yaml        merge=unityyamlmerge eol=lf linguist-language=yaml

# Optionally collapse Unity-generated files on GitHub diffs
# [attr]unity-yaml        merge=unityyamlmerge text linguist-language=yaml linguist-generated

# Unity source files
*.cginc                 text
*.compute               text linguist-language=hlsl
*.cs                    text diff=csharp
*.hlsl                  text linguist-language=hlsl
*.raytrace              text linguist-language=hlsl
*.shader                text

# Unity JSON files
*.asmdef                unity-json
*.asmref                unity-json
*.index                 unity-json
*.inputactions          unity-json
*.shadergraph           unity-json
*.shadersubgraph        unity-json

# Unity UI Toolkit files
*.tss                   text diff=css linguist-language=css
*.uss                   text diff=css linguist-language=css
*.uxml                  text linguist-language=xml linguist-detectable

# Unity YAML
*.anim                  unity-yaml
*.asset                 unity-yaml
*.brush                 unity-yaml
*.controller            unity-yaml
*.flare                 unity-yaml
*.fontsettings          unity-yaml
*.giparams              unity-yaml
*.guiskin               unity-yaml
*.lighting              unity-yaml
*.mask                  unity-yaml
*.mat                   unity-yaml
*.meta                  unity-yaml
*.mixer                 unity-yaml
*.overrideController    unity-yaml
*.playable              unity-yaml
*.prefab                unity-yaml
*.preset                unity-yaml
*.renderTexture         unity-yaml
*.scenetemplate         unity-yaml
*.shadervariants        unity-yaml
*.signal                unity-yaml
*.spriteatlas           unity-yaml
*.spriteatlasv2         unity-yaml
*.terrainlayer          unity-yaml
*.unity                 unity-yaml

# "physic" for 3D but "physics" for 2D
*.physicMaterial        unity-yaml
*.physicsMaterial2D     unity-yaml

# Exclude third-party plugins from GitHub stats
Assets/Plugins/**       linguist-vendored

# Exceptions for .asset files such as lightning pre-baking
LightingData.asset     binary
```

この内容は[ここ](https://github.com/gitattributes/gitattributes/blob/master/Unity.gitattributes)から拝借しています。

LFSは使わないのでその部分は除いています。

### .editorconfigを作る
Visual Studioではデフォルトの文字コードがUTF-8でないため、Visual Studioで日本語を書くと他のエディタで文字化けすることがあります。

これを防ぐため、以下の内容を書き込んだ`.editorconfig`をプロジェクトディレクトリの直下に置きます。

```text {name=".editorconfig"}
# Top-most EditorConfig file
root = true

# encode
[*.cs]
charset = utf-8
```

### プロジェクトをGit管理下におく
ここで、作成したプロジェクトをGitの管理下におきます。

ここではGitのコマンドと、Gitクライアントである[Fork](https://git-fork.com/)の2つで説明します。

Unity Hubで作成したプロジェクトのディレクトリに入ったうえで以下のコマンドを打ちます。
```bash
git init
```

Forkであれば、File > Init New Repository からプロジェクトのディレクトリを選択します。


### GitHub上でリポジトリを作成する
GitHub上でもリポジトリを作りましょう。Repositories > New repositoryなどと進んで、リポジトリ作成を行います。

ここで注意すべきなのは、リポジトリの公開範囲を正しく設定することです。公開するものであればpublic、公開しないものであればprivateです。

私が所属するサークルでは、開発中はprivateにしていることが多いです。

また、"Add a REDOME file"などにチェックを入れると少し面倒なことになります。ここではチェックを入れず、後から追加するほうがよいと思います。

{{< figure src="./src/create_repo.png" alt="リポジトリ作成画面">}}

必要事項を入力して右下の"Create repository"をクリックすれば完了です。

### リモートを追加する
ローカルのGitリポジトリにGitHubのリポジトリを追加します。

Unity Hubで作成したプロジェクトのディレクトリに入ったうえで以下のコマンドを打ちます。
```bash
git remote add origin {GitHubリポジトリのURL}
```

ForkではRemotes > Add New Remoteから追加できます。

これが終わったらいったんコミットしておきましょう。

{{< details summary="デフォルトのInitブランチ名を`main`にする" >}}
以下のコマンドを実行します。
```bash
git config --global init.defaultBranch main
```
{{< /details >}}

### READMEを書く
リモートにpushしたら、README.mdを追加しておきましょう。

ここには、Unityのバージョンやリポジトリの概要を書き込みます。

## Unityプロジェクトのセットアップ
最後にUnityプロジェクト自体のセットアップを行います。

### 必要なパッケージを入れる
開発に必要なパッケージを入れていきます。最近のエディタでは、よく使うパッケージはデフォルトで入っているので外部パッケージを入れていきます。

[Window] > [Package Manager] でPackageManagerを開いて左上の"+"から"Install Package from git URL"を選択し、必要に応じて以下のパッケージを入れていきます。

#### Extenject
依存性注入に使います。

まれに、Extenjectが依存するパッケージがデフォルトで入っていないことがあるので、エラー文を見てPackage Managerから不足しているものをインストールしてください。
(今回はAddressablesが入っていませんでした。[Window] > [Package Manager]で左側からUnity Registryを選択し、Addressablesを探してInstallを押します。)

```text
https://github.com/Mathijs-Bakker/Extenject.git?path=UnityProject/Assets/Plugins/Zenject/Source
```

#### UniTask
非同期処理に使います。
```text
https://github.com/Cysharp/UniTask.git?path=src/UniTask/Assets/Plugins/UniTask
```

#### R3
イベント関係で便利なライブラリです。UniTaskとの相性も良い。後述のNugetForUnityでR3のコア部分を別途インストールする必要があります。
```text
https://github.com/Cysharp/R3.git?path=src/R3.Unity/Assets/R3.Unity
```

#### Nuget For Unity
UnityでNugetが使えるようになります。
```text
https://github.com/GlitchEnzo/NuGetForUnity.git?path=/src/NuGetForUnity
```

NugetForUnityを使う場合は、`.gitignore`に以下を追記しておきましょう。Nugetによってインストールされたパッケージをignoreします。

```text {name=".gitignore (追記)"}
# Nuget for Unity Packages
/Assets/Packages/
/Assets/Packages.meta
```

注: Nugetのパッケージは初回起動時に解決されないため、このプロジェクトのリポジトリをクローンして最初に起動した際にエラーが出ることがありますが、この場合はIngoreしてからエディタを閉じて開きなおしてください。

#### その他
上記の他にも、人型の3Dモデルを扱うのに便利なVRMやLiltoonなど必要に応じて入れましょう。ここで入れなくても、必要になったときに入れれば問題ありません。

### エディタの設定を変更する
エディタの設定を変更することで作業効率が格段に上がります。

Edit > Project Settingsを開き、Editor > Enter Play Mode Settings > When entering Play Modeの項目を"Do not reload Domain or Scene"に変更します。

### ディレクトリ構成を整える
Unityで作業を行う際は、基本的にはAssets以下を触ることになると思います。このとき、以下のようなディレクトリ構成にするとわかりやすくてよいです。

```text
Assets/
├─ MyProject/
│   ├── Materials/
│   ├── Prefabs/
│   ├── Resources/
│   ├── Scenes/
│   ├── Scripts/
│
├─ MyProjectDemo/
│   ├── Materials/
│   ├── Prefabs/
│   ├── Resources/
│   ├── Scenes/
│   ├── Scripts/
```

## おわりに
お疲れさまでした。以上でプロジェクトの作成は完了です。

開発を進めるにつれて変更することもあると思うので、現状の設定がどのようになっているかを把握しておきましょう。