+++
title = 'Agent Development Kitを触ってみる #1'
date = '2025-04-17T11:08:46+09:00'
draft = false
summary = '今話題のADKに触れてみます'
tags = [ "ADK", "マルチエージェントシステム" ]
aliases = [ "/posts/20250417" ]
+++

つい最近公開されたAgent Development Kitを試してみようと思います。

この記事ではQuickstartとTutorialの2章までやっていきます。

## Quickstart
まずは以下のQuickstartを試してみます。

{{< linkcard "https://google.github.io/adk-docs/get-started/quickstart/" >}}

### 環境構築
uvを使います。簡単に環境構築ができるので便利です。

以下のコマンドで環境を作ります。

```bash
uv init adk_test -p 3.11
cd adk_test
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

{{< linkcard "https://google.github.io/adk-docs/tutorials/agent-team/" >}}

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
エージェントの定義をします。エージェントのインスタンスを作成するには`from google.adk.agents import Agent`で`Agent`をインポートします。

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
- `model`: 使用するLLM(`"gemini-2.0-flash"`は少し特殊な指定方法)
- `description`: エージェントの説明
- `instruction`: LLMの行動方法や人格、目標、割り当てられたリソース、与えられたツールをどのように活用するかの説明
- `tools`: エージェントが実際に使用できるPythonの関数のリスト

これらの引数を書くうえで重要な点は以下の2つです。
- `instruction`は可能な限り具体的にすることでLLMが自身の役割とツールの使用方法を理解できる。エラー処理についても明確に説明するほうがよい。
- `name`や`description`はADKの内部で用いられるため、適切な説明をつける必要がある。

### LiteLlm
ADKに統合されているLiteLLMを使うことで、様々なLLMをベースとしたAgentを定義できます。

`LiteLLM`を使う前に以下のコマンドでインストールします。

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
Quickstartでは、WebUIの機能によって(?)自動でSessionの管理などを行ってくれていたのですが、コードベースで書く場合はSessionやRunnerを自分で作成して管理します。

### Session
各セッションにおける会話を管理し履歴や状態を保存することができます。

セッションを扱うためには、`InMemorySessionService`を使います。以下の文でimportできます。

```py
from google.adk.sessions import InMemorySessionService
```

セッションは以下のようにして作成できます。

```py
session_service = InMemorySessionService()

session = session_service.create_session(
    app_name="weather_time_agent",
    user_id="user_1",
    session_id="session_1"
)
```

チュートリアルに記載されている各引数は以下のようになっています。
`app_name`: (必須)アプリケーションの名前
`user_id`: (必須)ユーザーのID(文字列)
`session_id`: セッションのID(文字列)

### Runner
Runnerはユーザ入力の受け取りやLLMやツールの呼び出し、セッションなどを管理します。

Runnerを使うには以下の文でimportします。

```py
from google.adk.runners import Runner
```

Runnerは以下のようにして作成できます。

```py
runner = Runner(
    agent=root_agent,
    app_name="weather_time_agent",
    session_service=session_service,
)
```

チュートリアルに記載されている各引数は以下のようになっています。ここに書かれているのは全て必須です。
`agent`: エージェント
`app_name`: アプリケーション名
`session_service`: セッションを管理するインスタンス(`InMemorySessionService`など)

なぜSessionとRunnerの両方に`app_name`の引数があるのかはわかりませんが、チュートリアルでは同じ名前を入れていました。

### エージェントと対話する
ここまでの作業を基に、エージェントとやり取りをするためのヘルパー関数を定義します。非同期関数となっていますが、これはLLMなどの外部APIを叩く操作に時間がかかるためです。非同期関数にすることで他の処理をブロッキングすることなく処理することができます。

```py
import asyncio
from google.genai import types

async def call_agent_async(query: str):
    """Sends a query to the agent and prints the final response."""
    print(f"\n>>> User Query: {query}")

    content = types.Content(role='user', parts=[types.Part(text=query)])

    final_response_text = "Agent did not produce a final response." # Default

    # 最終的な回答が得られるまで反復
    async for event in runner.run_async(user_id="user_1", session_id="session_1", new_message=content):
        # 以下をアンコメントすることで全てのログを出力可能
        # print(f"  [Event] Author: {event.author}, Type: {type(event).__name__}, Final: {event.is_final_response()}, Content: {event.content}")

        # is_final_response() で最後のレスポンスかを判定
        if event.is_final_response():
            if event.content and event.content.parts:
                # 最初のpartに応答があると仮定
                final_response_text = event.content.parts[0].text
            elif event.actions and event.actions.escalate: # 応答を得られない場合
                final_response_text = f"Agent escalated: {event.error_message or 'No specific message.'}"
            break # 終了

    print(f"<<< Agent Response: {final_response_text}")
```

上記の関数を実行する以下のプログラムを実行します。

```py
async def run_conversation():
    await call_agent_async("What is the weather like in London?")
    await call_agent_async("How about Paris?")
    await call_agent_async("Tell me the weather in New York")

await run_conversation()
```

実行結果は以下のようになりました。しっかり使えていそうです。

```text
>>> User Query: What is the weather like in London?
<<< Agent Response: I am sorry, I cannot get the weather information for London. The weather information for 'London' is not available.

>>> User Query: How about Paris?
<<< Agent Response: I am sorry, I cannot get the weather information for Paris. The weather information for 'Paris' is not available.

>>> User Query: Tell me the weather in New York
<<< Agent Response: OK. The weather in New York is sunny with a temperature of 25 degrees Celsius (41 degrees Fahrenheit).
```

## コードベースでの対話(まとめ)
ここまで、コードベースでの対話方法を説明していきました。ここまでで、ツールを使うことのできるLLMエージェントを作成できるようになりました。

次回の記事では、エージェントのチームを作る方法などを見ていきます。

一連のプログラムは以下を参照してください。

{{< details summary="一連のプログラム" >}}
Jupyterなどのノートブックで実行することを想定しています。

同階層にノートブックファイルと`.env`を置いてください。

### APIキーのロード
必要なAPIキーと環境変数名などは[このページ](https://docs.litellm.ai/docs/providers)から調べてください。

Gemini(Google AI Studio)の場合は`GEMINI_API_KEY`が必要です。Quickstartにおいて、`GOOGLE_API_KEY`に書いたAPIキーを以下のように書いてください。

```text {name=".env"}
GEMINI_API_KEY = {APIキー}
```

以下のコードで`.env`を読み込みます。

```py
from dotenv import load_dotenv
load_dotenv()
```

### エージェントが使うツールの定義
以下のコードでエージェントが使うツールを定義します。この部分はQuickstartと同じです。

```py
import datetime
from zoneinfo import ZoneInfo

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
```

### エージェントの定義
LiteLLMを使ってQuickstartと同じようなエージェントを定義します。

```py
from google.adk.agents import Agent
from google.adk.models.lite_llm import LiteLlm

try:
    root_agent = Agent(
        name="weather_time_agent",
        model=LiteLlm("gemini/gemini-2.0-flash"),
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

### セッションサービスの作成
セッションを管理するために`InMemorySessionService`のインスタンスを作ります。

変数`session`は今後使いませんが、user_idとsession_idで紐づけてエージェントを実行するため、`session_service.create_session`の実行は必須です。

```py
from google.adk.sessions import InMemorySessionService

session_service = InMemorySessionService()

session = session_service.create_session(
    app_name="weather_time_agent",
    user_id="user_1",
    session_id="session_1"
)
```

### Runnerの作成
以下のコードでRunnerを作成します。

```py
from google.adk.runners import Runner

runner = Runner(
    agent=root_agent,
    app_name="weather_time_agent",
    session_service=session_service,
)
```

### ヘルパー関数の定義
クエリを与えてエージェントを実行するためのヘルパー関数を以下のように定義します。

```py
import asyncio
from google.genai import types

async def call_agent_async(query: str):
    """Sends a query to the agent and prints the final response."""
    print(f"\n>>> User Query: {query}")

    # Prepare the user's message in ADK format
    content = types.Content(role='user', parts=[types.Part(text=query)])

    final_response_text = "Agent did not produce a final response." # Default

    # Key Concept: run_async executes the agent logic and yields Events.
    # We iterate through events to find the final answer.
    async for event in runner.run_async(user_id="user_1", session_id="session_1", new_message=content):
        # You can uncomment the line below to see *all* events during execution
        # print(f"  [Event] Author: {event.author}, Type: {type(event).__name__}, Final: {event.is_final_response()}, Content: {event.content}")

        # Key Concept: is_final_response() marks the concluding message for the turn.
        if event.is_final_response():
            if event.content and event.content.parts:
                # Assuming text response in the first part
                final_response_text = event.content.parts[0].text
            elif event.actions and event.actions.escalate: # Handle potential errors/escalations
                final_response_text = f"Agent escalated: {event.error_message or 'No specific message.'}"
            # Add more checks here if needed (e.g., specific error codes)
            break # Stop processing events once the final response is found

    print(f"<<< Agent Response: {final_response_text}")
```

### エージェントの実行
以下のコードでエージェントを実行します。

```py
async def run_conversation():
    await call_agent_async("What is the weather like in London?")
    await call_agent_async("How about Paris?") # Expecting the tool's error message
    await call_agent_async("Tell me the weather in New York")
    await call_agent_async("What time is it in New York?")

# Execute the conversation using await in an async context (like Colab/Jupyter)
await run_conversation()
```

一連のコードを実行して得られる結果は以下のようになりました。

ニューヨークの天気や時間を正しく回答していて、ツールによって情報を得られない場合はその旨を表示しています。

```text
>>> User Query: What is the weather like in London?
<<< Agent Response: I am sorry, I cannot get the weather information for London. There was an error.

>>> User Query: How about Paris?
<<< Agent Response: I am sorry, I cannot get the weather information for Paris. There was an error.

>>> User Query: Tell me the weather in New York
<<< Agent Response: OK. The weather in New York is sunny with a temperature of 25 degrees Celsius (41 degrees Fahrenheit).


>>> User Query: What time is it in New York?
<<< Agent Response: The current time in New York is 2025-04-20 11:30:19 EDT-0400.
```

{{< /details >}}

## おわりに
ADKの最低限の動かし方を学びました。次回は複数のエージェントを使ったエージェントチームの作成などをやります。
