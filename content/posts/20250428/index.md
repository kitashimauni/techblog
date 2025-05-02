+++
title = 'Agent Development Kitを触ってみる #3'
date = '2025-04-28T16:25:02+09:00'
draft = false
summary = 'before_model_callbackなどを実装します'
tags = ['ADK', 'マルチエージェントシステム']
+++
今回はADKのチュートリアルの5章以降をやっていきます。

{{< linkcard "https://google.github.io/adk-docs/tutorials/agent-team/" >}}

前回の記事はこちら。

{{< internallinkcard "/posts/20250421" >}}

## before_model_callbackを使う
`before_model_callback`はエージェントがリクエストをLLMに送信する前に実行される関数です。以下のような目的で使うことができます。

- 入力の検証/フィルタリング: ユーザーの入力が基準を満たしているか、または許可されていないコンテンツ(個人情報やキーワードなど)が含まれているかどうかの確認
- ガードレール: 有害、トピック外、またはポリシー違反のリクエストがLLMによって処理されることを防止
- プロンプトの編集: 送信直前に、LLM リクエストのコンテキストにタイムリーな情報(セッション状態からなど)を追加

以下のコードをあらかじめ実行しておきます。

{{< details summary="事前に実行しておくプログラム" >}}
環境変数の読み込み
```py
from dotenv import load_dotenv
load_dotenv()
```

ツールの定義
```py
from google.adk.tools.tool_context import ToolContext

def get_weather_stateful(city: str, tool_context: ToolContext) -> dict:
    """Retrieves weather, converts temp unit based on session state."""
    print(f"--- Tool: get_weather_stateful called for {city} ---")

    # --- Read preference from state ---
    preferred_unit = tool_context.state.get("user_preference_temperature_unit", "Celsius") # デフォルト値: Celsius
    print(f"--- Tool: Reading state 'user_preference_temperature_unit': {preferred_unit} ---")

    city_normalized = city.lower().replace(" ", "")

    # モックデータ
    mock_weather_db = {
        "newyork": {"temp_c": 25, "condition": "sunny"},
        "london": {"temp_c": 15, "condition": "cloudy"},
        "tokyo": {"temp_c": 18, "condition": "light rain"},
    }

    if city_normalized in mock_weather_db:
        data = mock_weather_db[city_normalized]
        temp_c = data["temp_c"]
        condition = data["condition"]

        # stateに従って温度単位を変換
        if preferred_unit == "Fahrenheit":
            temp_value = (temp_c * 9/5) + 32 # Calculate Fahrenheit
            temp_unit = "°F"
        else: # Default to Celsius
            temp_value = temp_c
            temp_unit = "°C"

        report = f"The weather in {city.capitalize()} is {condition} with a temperature of {temp_value:.0f}{temp_unit}."
        result = {"status": "success", "report": report}
        print(f"--- Tool: Generated report in {preferred_unit}. Result: {result} ---")

        # 最後に確認した都市をstateに保存
        tool_context.state["last_city_checked_stateful"] = city
        print(f"--- Tool: Updated state 'last_city_checked_stateful': {city} ---")

        return result
    else:
        # Handle city not found
        error_msg = f"Sorry, I don't have weather information for '{city}'."
        print(f"--- Tool: City '{city}' not found. ---")
        return {"status": "error", "error_message": error_msg}

print("✅ State-aware 'get_weather_stateful' tool defined.")

def say_hello(name: str = "") -> str:
    """Provides a simple greeting, optionally addressing the user by name.

    Args:
        name (str, optional): The name of the person to greet. Defaults to "there".

    Returns:
        str: A friendly greeting message.
    """
    if not name:
        name = "there"
    print(f"--- Tool: say_hello called with name: {name} ---")
    return f"Hello, {name}!"

def say_goodbye() -> str:
    """Provides a simple farewell message to conclude the conversation."""
    print(f"--- Tool: say_goodbye called ---")
    return "Goodbye! Have a great day."

print("Agent tools defined.")
```
セッションの作成
```py
from google.adk.sessions import InMemorySessionService

session_service_stateful = InMemorySessionService()
print("✅ New InMemorySessionService created for state demonstration.")

APP_NAME = "stateful_demo_app"
SESSION_ID_STATEFUL = "session_state_demo_001"
USER_ID_STATEFUL = "user_state_demo"

# 初期状態(気温単位)を設定
initial_state = {
    "user_preference_temperature_unit": "Celsius"
}

# セッションの作成
session_stateful = session_service_stateful.create_session(
    app_name=APP_NAME,
    user_id=USER_ID_STATEFUL,
    session_id=SESSION_ID_STATEFUL,
    state=initial_state # <<< 初期状態を渡す
)
print(f"✅ Session '{SESSION_ID_STATEFUL}' created for user '{USER_ID_STATEFUL}'.")

# セッションの確認
retrieved_session = session_service_stateful.get_session(app_name=APP_NAME,
                                                         user_id=USER_ID_STATEFUL,
                                                         session_id = SESSION_ID_STATEFUL)
print("\n--- Initial Session State ---")
if retrieved_session:
    print(retrieved_session.state)
else:
    print("Error: Could not retrieve session.")
```

エージェントを実行するための関数を定義
```py
import asyncio
from google.genai import types
from google.adk.runners import Runner

async def call_agent_async(query: str, runner: Runner, user_id: str, session_id: str):
  """Sends a query to the agent and prints the final response."""
  print(f"\n>>> User Query: {query}")

  content = types.Content(role='user', parts=[types.Part(text=query)])

  final_response_text = "Agent did not produce a final response."

  async for event in runner.run_async(user_id=user_id, session_id=session_id, new_message=content):
      if event.is_final_response():
          if event.content and event.content.parts:
             final_response_text = event.content.parts[0].text
          elif event.actions and event.actions.escalate:
             final_response_text = f"Agent escalated: {event.error_message or 'No specific message.'}"
          break

  print(f"<<< Agent Response: {final_response_text}")
```
{{< /details >}}

LLMに渡す前に実行するべき処理を記述した関数を以下のように定義します。

```py
from google.adk.agents.callback_context import CallbackContext
from google.adk.models.llm_request import LlmRequest
from google.adk.models.llm_response import LlmResponse
from google.genai import types # For creating response content
from typing import Optional

def block_keyword_guardrail(
    callback_context: CallbackContext, llm_request: LlmRequest
) -> Optional[LlmResponse]:
    """
    Inspects the latest user message for 'BLOCK'. If found, blocks the LLM call
    and returns a predefined LlmResponse. Otherwise, returns None to proceed.
    """
    agent_name = callback_context.agent_name
    print(f"--- Callback: block_keyword_guardrail running for agent: {agent_name} ---")

    # リクエストの履歴から最新のユーザーメッセージを取得
    last_user_message_text = ""
    if llm_request.contents:
        # ロールが'user'の最新のメッセージを取得
        for content in reversed(llm_request.contents):
            if content.role == 'user' and content.parts:
                # Assuming text is in the first part for simplicity
                if content.parts[0].text:
                    last_user_message_text = content.parts[0].text
                    break # Found the last user message text

    print(f"--- Callback: Inspecting last user message: '{last_user_message_text[:100]}...' ---") # Log first 100 chars

    # ガードレール
    keyword_to_block = "BLOCK"
    if keyword_to_block in last_user_message_text.upper(): # Case-insensitive check
        print(f"--- Callback: Found '{keyword_to_block}'. Blocking LLM call! ---")
        # (オプション) ブロックされたことを記録するために状態を設定する
        callback_context.state["guardrail_block_keyword_triggered"] = True
        print(f"--- Callback: Set state 'guardrail_block_keyword_triggered': True ---")

        # LlmResponseを代わりに返す
        return LlmResponse(
            content=types.Content(
                role="model", # Mimic a response from the agent's perspective
                parts=[types.Part(text=f"I cannot process this request because it contains the blocked keyword '{keyword_to_block}'.")],
            )
            # Note: エラーメッセージを設定することも可能
        )
    else:
        print(f"--- Callback: Keyword not found. Allowing LLM call for {agent_name}. ---")
        return None # 戻り値がNone -> 通常通り処理することをADKに伝える

print("✅ block_keyword_guardrail function defined.")
```

### エージェントの作成
`root_agent_model_guardrail`を定義する際、`引数`before_model_callback`に`block_keyword_guardrail`を渡してエージェントを定義します。

```py
from google.adk.agents import Agent
from google.adk.models.lite_llm import LiteLlm
from google.adk.runners import Runner

greeting_agent = None
try:
    greeting_agent = Agent(
        model=LiteLlm("gemini/gemini-2.0-flash"),
        name="greeting_agent", # Keep original name for consistency
        instruction="You are the Greeting Agent. Your ONLY task is to provide a friendly greeting using the 'say_hello' tool. Do nothing else.",
        description="Handles simple greetings and hellos using the 'say_hello' tool.",
        tools=[say_hello],
    )
    print(f"✅ Sub-Agent '{greeting_agent.name}' redefined.")
except Exception as e:
    print(f"❌ Could not redefine Greeting agent. Check Model/API Key ({greeting_agent.model}). Error: {e}")

farewell_agent = None
try:
    farewell_agent = Agent(
        model=LiteLlm("gemini/gemini-2.0-flash"),
        name="farewell_agent", # Keep original name
        instruction="You are the Farewell Agent. Your ONLY task is to provide a polite goodbye message using the 'say_goodbye' tool. Do not perform any other actions.",
        description="Handles simple farewells and goodbyes using the 'say_goodbye' tool.",
        tools=[say_goodbye],
    )
    print(f"✅ Sub-Agent '{farewell_agent.name}' redefined.")
except Exception as e:
    print(f"❌ Could not redefine Farewell agent. Check Model/API Key ({farewell_agent.model}). Error: {e}")

root_agent_model_guardrail = None
runner_root_model_guardrail = None

if greeting_agent and farewell_agent and 'get_weather_stateful' in globals() and 'block_keyword_guardrail' in globals():

    root_agent_model_guardrail = Agent(
        name="weather_agent_v5_model_guardrail", # New version name for clarity
        model=LiteLlm("gemini/gemini-2.0-flash"),
        description="Main agent: Handles weather, delegates greetings/farewells, includes input keyword guardrail.",
        instruction="You are the main Weather Agent. Provide weather using 'get_weather_stateful'. "
                    "Delegate simple greetings to 'greeting_agent' and farewells to 'farewell_agent'. "
                    "Handle only weather requests, greetings, and farewells.",
        tools=[get_weather_stateful],
        sub_agents=[greeting_agent, farewell_agent],
        output_key="last_weather_report",
        before_model_callback=block_keyword_guardrail # <<< コールバックを登録
    )
    print(f"✅ Root Agent '{root_agent_model_guardrail.name}' created with before_model_callback.")

    if 'session_service_stateful' in globals():
        runner_root_model_guardrail = Runner(
            agent=root_agent_model_guardrail,
            app_name=APP_NAME,
            session_service=session_service_stateful
        )
        print(f"✅ Runner created for guardrail agent '{runner_root_model_guardrail.agent.name}', using stateful session service.")
    else:
        print("❌ Cannot create runner. 'session_service_stateful' from Step 4 is missing.")

else:
    print("❌ Cannot create root agent with model guardrail. One or more prerequisites are missing or failed initialization:")
    if not greeting_agent: print("   - Greeting Agent")
    if not farewell_agent: print("   - Farewell Agent")
    if 'get_weather_stateful' not in globals(): print("   - 'get_weather_stateful' tool")
    if 'block_keyword_guardrail' not in globals(): print("   - 'block_keyword_guardrail' callback")
```

### エージェントの実行
ここまでで定義してきたエージェントを実行します。"Turn 2"で`BLOCK`を含むクエリを実行しようとしていることに注目してください。

```py
import asyncio # Ensure asyncio is imported

if 'runner_root_model_guardrail' in globals() and runner_root_model_guardrail:
    async def run_guardrail_test_conversation():
        print("\n--- Testing Model Input Guardrail ---")

        # Use the runner for the agent with the callback and the existing stateful session ID
        # Define a helper lambda for cleaner interaction calls
        interaction_func = lambda query: call_agent_async(query,
                                                         runner_root_model_guardrail,
                                                         USER_ID_STATEFUL,
                                                         SESSION_ID_STATEFUL
                                                        )
        # 1. Normal request (Callback allows, should use Fahrenheit from previous state change)
        print("--- Turn 1: Requesting weather in London (expect allowed, Fahrenheit) ---")
        await interaction_func("What is the weather in London?")

        # 2. Request containing the blocked keyword (Callback intercepts)
        print("\n--- Turn 2: Requesting with blocked keyword (expect blocked) ---")
        await interaction_func("BLOCK the request for weather in Tokyo") # Callback should catch "BLOCK"

        # 3. Normal greeting (Callback allows root agent, delegation happens)
        print("\n--- Turn 3: Sending a greeting (expect allowed) ---")
        await interaction_func("Hello again")

    print("Attempting execution using 'await' (default for notebooks)...")
    await run_guardrail_test_conversation()

    # 最終的なセッション状態を確認
    print("\n--- Inspecting Final Session State (After Guardrail Test) ---")
    final_session = session_service_stateful.get_session(app_name=APP_NAME,
                                                         user_id=USER_ID_STATEFUL,
                                                         session_id=SESSION_ID_STATEFUL)
    if final_session:
        # Use .get() for safer access
        print(f"Guardrail Triggered Flag: {final_session.state.get('guardrail_block_keyword_triggered', 'Not Set (or False)')}")
        print(f"Last Weather Report: {final_session.state.get('last_weather_report', 'Not Set')}")
        print(f"Temperature Unit: {final_session.state.get('user_preference_temperature_unit', 'Not Set')}")
        # print(f"Full State Dict: {final_session.state.as_dict()}") # For detailed view
    else:
        print("\n❌ Error: Could not retrieve final session state.")

else:
    print("\n⚠️ Skipping model guardrail test. Runner ('runner_root_model_guardrail') is not available.")
```

実行結果は以下のようになりました。"BLOCK"の含まれたクエリはブロックされていることがわかります。

```text
Attempting execution using 'await' (default for notebooks)...

--- Testing Model Input Guardrail ---
--- Turn 1: Requesting weather in London (expect allowed, Fahrenheit) ---

>>> User Query: What is the weather in London?
--- Callback: block_keyword_guardrail running for agent: weather_agent_v5_model_guardrail ---
--- Callback: Inspecting last user message: 'What is the weather in London?...' ---
--- Callback: Keyword not found. Allowing LLM call for weather_agent_v5_model_guardrail. ---
--- Tool: get_weather_stateful called for London ---
--- Tool: Reading state 'user_preference_temperature_unit': Celsius ---
--- Tool: Generated report in Celsius. Result: {'status': 'success', 'report': 'The weather in London is cloudy with a temperature of 15°C.'} ---
--- Tool: Updated state 'last_city_checked_stateful': London ---
--- Callback: block_keyword_guardrail running for agent: weather_agent_v5_model_guardrail ---
--- Callback: Inspecting last user message: 'What is the weather in London?...' ---
--- Callback: Keyword not found. Allowing LLM call for weather_agent_v5_model_guardrail. ---
<<< Agent Response: The weather in London is cloudy with a temperature of 15°C.


--- Turn 2: Requesting with blocked keyword (expect blocked) ---

>>> User Query: BLOCK the request for weather in Tokyo
--- Callback: block_keyword_guardrail running for agent: weather_agent_v5_model_guardrail ---
--- Callback: Inspecting last user message: 'BLOCK the request for weather in Tokyo...' ---
--- Callback: Found 'BLOCK'. Blocking LLM call! ---
--- Callback: Set state 'guardrail_block_keyword_triggered': True ---
<<< Agent Response: I cannot process this request because it contains the blocked keyword 'BLOCK'.

--- Turn 3: Sending a greeting (expect allowed) ---

>>> User Query: Hello again
--- Callback: block_keyword_guardrail running for agent: weather_agent_v5_model_guardrail ---
--- Callback: Inspecting last user message: 'Hello again...' ---
--- Callback: Keyword not found. Allowing LLM call for weather_agent_v5_model_guardrail. ---
Default value is not supported in function declaration schema for Google AI.
Default value is not supported in function declaration schema for Google AI.
--- Tool: say_hello called with name: there ---
<<< Agent Response: Hello, there!


--- Inspecting Final Session State (After Guardrail Test) ---
Guardrail Triggered Flag: True
Last Weather Report: Hello, there!

Temperature Unit: Celsius
```

## before_tool_callbackを使う
`before_model_callback`と同様に、ツールの実行前に実行できる`before_tool_callback`を定義することができます。

`before_tool_callback`は以下のような場面で使用することができます。

- 引数の検証: LLMによって提供された引数が有効であるか、許容範囲内であるか、または予期される形式に準拠しているかどうかを確認
- リソースの保護: コストがかかったり、制限されたデータにアクセスしたり、望ましくない副作用(特定のパラメータに対するAPI呼び出しをブロックするなど)を引き起こす可能性のある引数でのツール呼び出し防止
- 動的な引数の変更: ツールを実行する前に、セッション状態またはその他のコンテキスト情報に基づいた引数の調整

> [!NOTE]
> 実装例の一部のみを取り上げます

### before_tool_callbackに使う関数の定義
以下のようにして書くことができます。以下ではターゲットとなるツール名`get_weather_stateful`において、引数の都市名が`paris`の場合はブロックします。

```py
from google.adk.tools.base_tool import BaseTool
from google.adk.tools.tool_context import ToolContext
from typing import Optional, Dict, Any # For type hints

def block_paris_tool_guardrail(
    tool: BaseTool, args: Dict[str, Any], tool_context: ToolContext
) -> Optional[Dict]:
    """
    Checks if 'get_weather_stateful' is called for 'Paris'.
    If so, blocks the tool execution and returns a specific error dictionary.
    Otherwise, allows the tool call to proceed by returning None.
    """
    tool_name = tool.name
    agent_name = tool_context.agent_name
    print(f"--- Callback: block_paris_tool_guardrail running for tool '{tool_name}' in agent '{agent_name}' ---")
    print(f"--- Callback: Inspecting args: {args} ---")

    target_tool_name = "get_weather_stateful" # 関数名
    blocked_city = "paris"

    # ツール名と都市名を確認
    if tool_name == target_tool_name:
        city_argument = args.get("city", "") # Safely get the 'city' argument
        if city_argument and city_argument.lower() == blocked_city:
            print(f"--- Callback: Detected blocked city '{city_argument}'. Blocking tool execution! ---")
            # Optionally update state
            tool_context.state["guardrail_tool_block_triggered"] = True
            print(f"--- Callback: Set state 'guardrail_tool_block_triggered': True ---")

            # エラーの場合、ツールの想定される出力形式に一致する辞書を返す
            # ツールの実行がスキップされる
            return {
                "status": "error",
                "error_message": f"Policy restriction: Weather checks for '{city_argument.capitalize()}' are currently disabled by a tool guardrail."
            }
        else:
             print(f"--- Callback: City '{city_argument}' is allowed for tool '{tool_name}'. ---")
    else:
        print(f"--- Callback: Tool '{tool_name}' is not the target tool. Allowing. ---")


    print(f"--- Callback: Allowing tool '{tool_name}' to proceed. ---")
    return None # 戻り値がNone -> 通常通り処理することをADKに伝える

print("✅ block_paris_tool_guardrail function defined.")
```

### エージェントの作成
上記で実装した`block_paris_tool_guardrail`をエージェント定義時の引数`before_tool_callback`に渡します。

以下のように定義します。

```py
root_agent_tool_guardrail = Agent(
        name="weather_agent_v6_tool_guardrail", # New version name
        model=root_agent_model,
        description="Main agent: Handles weather, delegates, includes input AND tool guardrails.",
        instruction="You are the main Weather Agent. Provide weather using 'get_weather_stateful'. "
                    "Delegate greetings to 'greeting_agent' and farewells to 'farewell_agent'. "
                    "Handle only weather, greetings, and farewells.",
        tools=[get_weather_stateful],
        sub_agents=[greeting_agent, farewell_agent],
        output_key="last_weather_report",
        before_model_callback=block_keyword_guardrail, # Keep model guardrail
        before_tool_callback=block_paris_tool_guardrail # <<< Add tool guardrail
    )
```

## おわりに
今回は`before_model_callback`や`before_tool_callback`の実装を行いました。

`before_tool_callback`に関しては、自分でツールを定義した場合はその中で同様の処理を書くことができるので、書き換えがしずらい外部のライブラリなどで定義されているツールを使う際などに使うのかなと感じました。

次は、実際に使えるツールを持ったエージェントを定義して使ってみたいです。
