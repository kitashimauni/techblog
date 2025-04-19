+++
title = 'Agent Development Kitに触ってみる'
date = '2025-04-17T11:08:46+09:00'
draft = false
summary = '今話題のADKに触れてみます'
tags = ['ADK', 'マルチエージェントシステム']
+++

つい最近公開されたAgent Development Kitを試してみようと思います。

## Quickstart
まずは以下のQuickstartを試してみます。

{{< linkcard "https://google.github.io/adk-docs/get-started/quickstart/" >}}

### 環境構築
uvを使います。簡単に環境構築ができるので便利です。

以下のコマンドで環境を作ります。

```bash
uv init adk_test -p 3.11
uv add google-adk
```

### ファイルの作成
以下の手順でファイルを作っていきます。

まずは`multi_tool_agent`というフォルダを作成し、`__init__.py`を作ります。

```bash
mkdir multi_tool_agent/
echo "from . import agent" > multi_tool_agent/__init__.py
```

次に、`multi_tool_agent`の中に`agent.py`を作り、以下を書き込みます。

```py {name="multi_tool_agent/agent.py"}
import datetime
from zoneinfo import ZoneInfo
from google.adk.agents import Agent

def get_weather(city: str) -> dict:
    """Retrieves the current weather report for a specified city.

    Args:
        city (str): The name of the city for which to retrieve the weather report.

    Returns:
        dict: status and result or error msg.
    """
    if city.lower() == "new york":
        return {
            "status": "success",
            "report": (
                "The weather in New York is sunny with a temperature of 25 degrees"
                " Celsius (41 degrees Fahrenheit)."
            ),
        }
    else:
        return {
            "status": "error",
            "error_message": f"Weather information for '{city}' is not available.",
        }


def get_current_time(city: str) -> dict:
    """Returns the current time in a specified city.

    Args:
        city (str): The name of the city for which to retrieve the current time.

    Returns:
        dict: status and result or error msg.
    """

    if city.lower() == "new york":
        tz_identifier = "America/New_York"
    else:
        return {
            "status": "error",
            "error_message": (
                f"Sorry, I don't have timezone information for {city}."
            ),
        }

    tz = ZoneInfo(tz_identifier)
    now = datetime.datetime.now(tz)
    report = (
        f'The current time in {city} is {now.strftime("%Y-%m-%d %H:%M:%S %Z%z")}'
    )
    return {"status": "success", "report": report}


root_agent = Agent(
    name="weather_time_agent",
    model="gemini-2.0-flash",
    description=(
        "Agent to answer questions about the time and weather in a city."
    ),
    instruction=(
        "You are a helpful agent who can answer user questions about the time and weather in a city."
    ),
    tools=[get_weather, get_current_time],
)
```

Google AI StudioからAPIキーを取得します。

{{< linkcard "https://aistudio.google.com/apikey" >}}

`multi_tool_agent`に`.env`というファイルを作り、取得したAPIキーを以下の形式で貼り付けます。

```text {name="multi_tool_agent/.env"}
GOOGLE_GENAI_USE_VERTEXAI=FALSE
GOOGLE_API_KEY={取得したAPIキー}
```

### 動かしてみる
以下のコマンドでWEBのUIが立ち上がります。

```bash
uv run adk web
```

この状態でブラウザから`http://localhost:8000`にアクセスすると以下のようなUIが表示されます。

{{< figure src="src/ui_first.png" alt="UIを立ち上げた際の初期状態" >}}

左上の[Select an agent]から「multi_tool_agent」を選択すると以下のようなチャット画面が表示されます。

{{< figure src="src/ui_chat.png" alt="チャット画面" >}}

試しにニューヨーク(New York)の天気と時間を聞いた結果、以下のようになりました。天気と時間を取得できていることがわかります。

{{< figure src="src/chat_newyork.png" alt="New Yorkの天気と時間を聞いた結果" >}}

次に、パリ(Paris)の天気と時間を聞いた結果は以下のようになりました。パリの時間と天気は取得できていないことがわかります。

{{< figure src="src/chat_paris.png" alt="Parisの天気と時間を聞いた結果" >}}

Quickstartは以上で終了です。コピー&ペーストだけでニューヨークの天気と時間を答えてくれるエージェントができました。


## 少し深掘り
以下のチュートリアルを見ながらQuickstartで何をしていたのかを見ていきます。

{{< linkcard "https://google.github.io/adk-docs/get-started/tutorial/" >}}

### ツールの定義
例として、agent.pyの中では以下の部分で天気情報を取得するツールの定義を行っています。

```py {name="multi_tool_agent/agent.py (一部抜粋)"}
def get_weather(city: str) -> dict:
    """Retrieves the current weather report for a specified city.

    Args:
        city (str): The name of the city for which to retrieve the weather report.

    Returns:
        dict: status and result or error msg.
    """
    if city.lower() == "new york":
        return {
            "status": "success",
            "report": (
                "The weather in New York is sunny with a temperature of 25 degrees"
                " Celsius (41 degrees Fahrenheit)."
            ),
        }
    else:
        return {
            "status": "error",
            "error_message": f"Weather information for '{city}' is not available.",
        }
```

文字列で以下の情報を示すことが重要です。

- ツールの機能
- いつ使うのか
- 必要な引数
- 返される情報

LLMはこの文字列を基にツールを使用するため、適切にツールの説明を記述しなければなりません。

### エージェントの定義
エージェントの定義をします。エージェントのインスタンスは`from google.adk.agents import Agent`で作成できます。

Quickstartでエージェントの定義に該当する部分は以下の部分です。

```py {name="multi_tool_agent/agent.py (一部抜粋)"}
root_agent = Agent(
    name="weather_time_agent",
    model="gemini-2.0-flash",
    description=(
        "Agent to answer questions about the time and weather in a city."
    ),
    instruction=(
        "You are a helpful agent who can answer user questions about the time and weather in a city."
    ),
    tools=[get_weather, get_current_time],
)
```

重要な引数は以下の通りです。

- `name`: エージェントの一意な名前
- `model`: 使用するLLM
- `description`: エージェントの説明
- `instruction`: LLMの行動方法や人格、目標、割り当てられたリソース、与えられたツールをどのように活用するかの説明
- `tools`: エージェントが実際に使用できるPythonの関数のリスト

これらの引数を書くうえで重要な点は以下の2つです。
- `instruction`は可能な限り具体的にすることでLLMが自身の役割とツールの使用方法を理解できる。エラー処理についても明確に説明するほうがよい。
- `name`や`description`はADKの内部で用いられるため、適切な説明をつける必要がある。

### LiteLlm
ADKに統合されているLiteLLMを使うことで、様々なLLMをベースとしたAgentを定義できます。

`LiteLLM`を使うには以下のコマンドでインストールします。

```bash
uv add litellm
```

おそらく統合元のLiteLLMで利用可能なモデルは全て使うことができると思われます。以下にLiteLLMで利用可能なProviderの一覧を見ることができます。OpenAIをはじめ、Hugging FaceやOllamaなど、様々なインターフェースがサポートされています。

{{< linkcard "https://docs.litellm.ai/docs/providers" >}}

`LiteLLM`をimportするには、以下の文を書きます。

```py
from google.adk.models.lite_llm import LiteLLM
```

さらに、Agentを定義している部分を以下のように書き換えます。**このとき、必要に応じてAPIキーなどを環境変数に置いておく必要があります**。`python-dotenv`等を用いて`.env`ファイルで管理できるとよさそうです。

また、`try...except`構文を使うことで、エラーハンドリングすることが推奨されているようです。

```py
try:
    root_agent = Agent(
        name="weather_time_agent",
        model=LiteLlm("provider/model_name"),
        description=(
            "Agent to answer questions about the time and weather in a city."
        ),
        instruction=(
            "You are a helpful agent who can answer user questions about the time and weather in a city."
        ),
        tools=[get_weather, get_current_time],
    )
except Exception as e:
    print(f"Counld not create Agent. Error: {e}")
```

## コードベースで対話する
Quickstartでは、WebUIの機能によって(?)自動でSessionの管理などを行ってくれていたのですが、コードベースで書く場合はSessionや

### Session