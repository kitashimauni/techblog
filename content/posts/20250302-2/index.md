+++
title = 'Unityで開発をするうえで知っていると便利なC#の機能'
date = '2025-03-02T19:21:33+09:00'
draft = false
summary = '型推論やNULLチェック、プロパティについて簡単に説明します'
tags = ['C#', 'Unity']
+++

C#の機能についてある程度知っておくとUnityのコードが書きやすくなります。個人的な認識ですが、知っておきたいC#の機能を挙げます。

## 型推論
C#の型推論について簡単に書いておきます。C#では`var`キーワードを使うことで型推論させることができます。長いクラス名などを書く必要がなくなるため便利です。

```c# {name="型推論の例"}
// 変数定義の型推論
var xs = new List<int>();
// newキーワードの型推論
List<int> ys = new();
```

公式ドキュメントは以下を参照してください。

{{< linkcard "https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/declarations" >}}

## NULLチェック
あらゆる言語において、NULLに対してメンバ変数やメソッドを参照しようとするとエラー・例外となります(C#では`NullReferenceException`)。そのため、変数がNULLになりうる場合は参照する前にその変数がNULLでないかチェックする必要があり、これをチェックする単純な方法として以下のようにif文を使う方法があります。

```c# {name="if文を用いたNullチェック"}
var obj = GetObj(); // nullを返す可能性があるメソッド
if (obj != null) // nullでないことを確かめてから実行
{
    obj.Execute(); 
}
else
{
    // objがnullだった場合の処理
}
```

この方法は簡単で分かりやすいですが、いちいちNULLチェックをしていてはコードが無駄に長くなってしまいます。高度な制御を必要としない場合、以下のようにしてNULLチェックを簡素化できます。

### null条件演算子
null条件演算子は「`?.`」で、メンバアクセス式「`.`」の代わりに使用することができます。


`a?.b`という式において`a`が`null`のとき、`b`は参照されず結果が`null`となります。つまり、この演算子を使うと結果が`null`になった時点で、残りの演算が行われず、NULL参照を回避することができます。

この性質を利用して、上記のNULLチェックは以下のように書くことができます。

```c# {name="null条件演算子を使った例"}
var obj = GetObj();
obj?.Execute(); // objがnullでないときメソッドを実行
```

注意点としては、上の例のようにメソッドを実行して戻り値を受け取らない場合、メソッドが実行されたかここでは判別できない点が挙げられます。細かく制御したい場合は素直にif文を使うのがよいでしょう。

この演算子は、Unityのゲーム開発においては`event Action`でよく使います。イベントを発火する(`Invoke`を呼び出す)際に、何も関数が渡されていないとエラーとなってしまうので事前にNULLチェックが必要です。

具体的には、以下のようにイベントを発火することでエラーを回避します。

```c# {name="NULLチェックをしてイベント発火する例"}
public event Action OnStateChanged; // GameStateが変更されたときに発火するイベント
OnGameStateChanged?.Invoke(); // NULLチェックをしたうえでイベントを発火
```

配列の参照に使用するインデクサについてもnull条件演算子「`?[]`」があります。公式ドキュメントは以下を参照してください。

{{< linkcard "https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/member-access-operators" >}}

また、あまり使ったことはありませんが、null合体演算子も覚えておくといつか使えるときがくるかもしれません。

{{< linkcard "https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/null-coalescing-operator" >}}

## プロパティ

### メンバ変数のカプセル化
C#の便利な機能の1つにプロパティがあります。オブジェクト指向の言語では、インスタンス内のメンバ変数の値を取得・変更する際にインスタンスの外部から直接アクセスできないようにします。これは**カプセル化**の一環であり、以下のようなコードは避けるべきです。

```c# {name="避けるべきコード"}
public class BadExamlpe
{
    public int State;

    public BadExample()
    {
        state = 0;
    }
}

public class Main()
{
    private BadExample obj = new();
    obj.State = 1; // 外部から自由に変更でき
    var x = obj.State; // 取得もできてしまう
}
```

カプセル化するには**アクセサ**と呼ばれるメソッドを実装します。これによってメンバ変数へのアクセスを制限したり、値が変更されたときの処理を追加したりできます。以下の例では、変数`state`に対して外部からは変更できず取得しかできません。

```c# {name="カプセル化したコード"}
public class EncapsuledExample
{
    private int state;

    public EncapsuledExample()
    {
        state = 0;
    }

    public int GetState() { return state; }
}

public class Main()
{
    private EncapsuledExample obj = new();
    // obj.State = 1; これはできない
    var x = obj.GetState(); // アクセサを使って取得できる
}
```

### プロパティの使い方
さて、ここまでメンバ変数のカプセル化について書いてきたのですが、変数ごとにアクセサを書くのは面倒な作業です。そこで、C#には**プロパティ**という機能があります。上記の例をプロパティを使って書くと次のようになります。

```c# {name="プロパティを使ったコード"}
public class PropertyExample1
{
    public int State { get; private set; };
    // public int State { get; private set; } = 0; で初期化することも可能

    public PropertyExample1()
    {
        State = 0;
    }
}

public class Main
{
    PropertyExample1 obj = new();
    // obj.State = 1; これはできない
    var x = obj.State; // メンバ変数と同じ要領でアクセスできる
}
```

メンバ変数の定義と同時にアクセサも定義するイメージです。実はこの記法は以下のプロパティの書き方を省略した形で、省略せずにプロパティを定義するときはプロパティの本体が必要なことに注意が必要です。

```c# {name="省略しない記法"}
public class PropertyExample2
{
    public int State
    {
        get => _state; // _stateを返す
        private set
        {
            _state = value; // 渡された値を_stateに代入する
        }
    }
    private int _state; // 本体

    public PropertyExample2()
    {
        State = 0;
    }
}
```

これを応用することで、値が変更された時にイベントを発火するといった制御は、プロパティを使って以下のように書くことができます。
```c# {name="値が変更されたときにイベントを発火する"}
... // using
public class GameStateManager
{
    public event Action<GameState> OnGameStateChanged; // GameStateが変更されたときに発火するイベント

    public GameState GameState // プロパティ
    {
        get => gameState; // 取得(本体の値を返す)
        set // 値が変更されたとき
        {
            gameState = value; // 本体に値を代入
            OnGameStateChanged?.Invoke(gameState); // イベントを発火
            Debug.Log($"GameState changed to {value}");
        }
    }

    private GameState gameState; // 本体
}
```

## おわりに
C#で使える便利な記法を紹介しました。これらを使うとコードを簡潔にすることができるため、ぜひ使い方を覚えましょう。
