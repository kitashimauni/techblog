+++
title = 'Agent Development Kitを触ってみる #2'
date = '2025-04-21T22:39:39+09:00'
draft = false
summary = 'エージェントチームなどを実装します'
tags = [ 'ADK', 'マルチエージェントシステム' ]
+++

今回はADKのチュートリアルの3章以降をやっていきます。

{{< linkcard "https://google.github.io/adk-docs/tutorials/agent-team/" >}}

前回の記事はこちら。

{{< internallinkcard "/posts/20250417" >}}

## エージェントチームを構築する
複数のエージェントを使ってエージェントチームを構築します。

エージェントを複数作成してチームを構築する利点として、保守が容易になる、スケーラビリティの向上などが挙げられます。

ルートエージェントと2つのサブエージェントからなるエージェントチームを構築していきます。

本記事ではノートブックで実行することを前提に記述します。

### エージェントのツールの定義
各エージェントに持たせるツールを以下のようにそれぞれ定義します。

```py
def get_weather(city: str) -> dict:
    """Retrieves the current weather report for a specified city.

    Args:
        city (str): The name of the city (e.g., "New York", "London", "Tokyo").

    Returns:
        dict: A dictionary containing the weather information.
              Includes a 'status' key ('success' or 'error').
              If 'success', includes a 'report' key with weather details.
              If 'error', includes an 'error_message' key.
    """
    # Best Practice: Log tool execution for easier debugging
    print(f"--- Tool: get_weather called for city: {city} ---")
    city_normalized = city.lower().replace(" ", "") # Basic input normalization

    # Mock weather data for simplicity
    mock_weather_db = {
        "newyork": {"status": "success", "report": "The weather in New York is sunny with a temperature of 25°C."},
        "london": {"status": "success", "report": "It's cloudy in London with a temperature of 15°C."},
        "tokyo": {"status": "success", "report": "Tokyo is experiencing light rain and a temperature of 18°C."},
    }

    # Best Practice: Handle potential errors gracefully within the tool
    if city_normalized in mock_weather_db:
        return mock_weather_db[city_normalized]
    else:
        return {"status": "error", "error_message": f"Sorry, I don't have weather information for '{city}'."}

def say_hello(name: str = "there") -> str:
    """Provides a simple greeting, optionally addressing the user by name.

    Args:
        name (str, optional): The name of the person to greet. Defaults to "there".

    Returns:
        str: A friendly greeting message.
    """
    print(f"--- Tool: say_hello called with name: {name} ---")
    return f"Hello, {name}!"

def say_goodbye() -> str:
    """Provides a simple farewell message to conclude the conversation."""
    print(f"--- Tool: say_goodbye called ---")
    return "Goodbye! Have a great day."

print("Agent tools defined.")
```

### サブエージェントの定義
サブエージェントを定義します。定義の方法はこれまでと同様です。

今回は全てのエージェントを`gemini/gemini-2.0-flash`にします。あらかじめノートブックと同階層に`.env`を作成し、`GEMINI_API_KEY={APIキー}`を書き込んでください。

```py
from dotenv import load_dotenv
from google.adk.agents import Agent
from google.adk.models.lite_llm import LiteLlm

load_dotenv()

# --- Greeting Agent ---
greeting_agent = None
try:
    greeting_agent = Agent(
        model=LiteLlm(model="gemini/gemini-2.0-flash"),
        name="greeting_agent",
        instruction="You are the Greeting Agent. Your ONLY task is to provide a friendly greeting to the user. "
                    "Use the 'say_hello' tool to generate the greeting. "
                    "If the user provides their name, make sure to pass it to the tool. "
                    "Do not engage in any other conversation or tasks.",
        description="Handles simple greetings and hellos using the 'say_hello' tool.", # Crucial for delegation
        tools=[say_hello],
    )
    print(f"✅ Agent '{greeting_agent.name}' created.")
except Exception as e:
    print(f"❌ Could not create Greeting agent. Check API Key. Error: {e}")

# --- Farewell Agent ---
farewell_agent = None
try:
    farewell_agent = Agent(
        model=LiteLlm(model="gemini/gemini-2.0-flash"),
        name="farewell_agent",
        instruction="You are the Farewell Agent. Your ONLY task is to provide a polite goodbye message. "
                    "Use the 'say_goodbye' tool when the user indicates they are leaving or ending the conversation "
                    "(e.g., using words like 'bye', 'goodbye', 'thanks bye', 'see you'). "
                    "Do not perform any other actions.",
        description="Handles simple farewells and goodbyes using the 'say_goodbye' tool.", # Crucial for delegation
        tools=[say_goodbye],
    )
    print(f"✅ Agent '{farewell_agent.name}' created.")
except Exception as e:
    print(f"❌ Could not create Farewell agent. Check API Key. Error: {e}")
```

### ルートエージェントの定義
続いてルートエージェントを定義します。

エージェントを定義する方法は基本的には同じですが、`Agent`の引数に`sub_agents`を渡して

```py
root_agent = None
runner_root = None # Initialize runner

if greeting_agent and farewell_agent and 'get_weather' in globals():
    weather_agent_team = Agent(
        name="weather_agent_v2", # Give it a new version name
        model=LiteLlm(model="gemini/gemini-2.0-flash"),
        description="The main coordinator agent. Handles weather requests and delegates greetings/farewells to specialists.",
        instruction="You are the main Weather Agent coordinating a team. Your primary responsibility is to provide weather information. "
                    "Use the 'get_weather' tool ONLY for specific weather requests (e.g., 'weather in London'). "
                    "You have specialized sub-agents: "
                    "1. 'greeting_agent': Handles simple greetings like 'Hi', 'Hello'. Delegate to it for these. "
                    "2. 'farewell_agent': Handles simple farewells like 'Bye', 'See you'. Delegate to it for these. "
                    "Analyze the user's query. If it's a greeting, delegate to 'greeting_agent'. If it's a farewell, delegate to 'farewell_agent'. "
                    "If it's a weather request, handle it yourself using 'get_weather'. "
                    "For anything else, respond appropriately or state you cannot handle it.",
        tools=[get_weather],
        # Key change: Link the sub-agents here!
        sub_agents=[greeting_agent, farewell_agent]
    )
    print(f"✅ Root Agent '{weather_agent_team.name}' created with sub-agents: {[sa.name for sa in weather_agent_team.sub_agents]}")

else:
    print("❌ Cannot create root agent because one or more sub-agents failed to initialize or 'get_weather' tool is missing.")
    if not greeting_agent:
        print(" - Greeting Agent is missing.")
    if not farewell_agent:
        print(" - Farewell Agent is missing.")
    if 'get_weather' not in globals():
        print(" - get_weather function is missing.")
```

### エージェントチームの実行
エージェントチームを実行するために、ヘルパー関数を以下のように定義します。

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

そのうえで、以下のコードでエージェントチームを実行します。

```py
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService

root_agent_var_name = 'root_agent'
if 'weather_agent_team' in globals():
    root_agent_var_name = 'weather_agent_team'
elif 'root_agent' not in globals():
    print("⚠️ Root agent ('root_agent' or 'weather_agent_team') not found. Cannot define run_team_conversation.")
    root_agent = None

if root_agent_var_name in globals() and globals()[root_agent_var_name]:
    async def run_team_conversation():
        print("\n--- Testing Agent Team Delegation ---")
        # InMemorySessionService is simple, non-persistent storage for this tutorial.
        session_service = InMemorySessionService()

        # Define constants for identifying the interaction context
        APP_NAME = "weather_tutorial_agent_team"
        USER_ID = "user_1_agent_team"
        SESSION_ID = "session_001_agent_team" # Using a fixed ID for simplicity

        # Create the specific session where the conversation will happen
        session = session_service.create_session(
            app_name=APP_NAME,
            user_id=USER_ID,
            session_id=SESSION_ID
        )
        print(f"Session created: App='{APP_NAME}', User='{USER_ID}', Session='{SESSION_ID}'")

        # --- Get the actual root agent object ---
        # Use the determined variable name
        actual_root_agent = globals()[root_agent_var_name]

        # Create a runner specific to this agent team test
        runner_agent_team = Runner(
            agent=actual_root_agent, # Use the root agent object
            app_name=APP_NAME,       # Use the specific app name
            session_service=session_service # Use the specific session service
            )
        # Corrected print statement to show the actual root agent's name
        print(f"Runner created for agent '{actual_root_agent.name}'.")

        # Always interact via the root agent's runner, passing the correct IDs
        await call_agent_async(query = "Hello there!",
                               runner=runner_agent_team,
                               user_id=USER_ID,
                               session_id=SESSION_ID)
        await call_agent_async(query = "What is the weather in New York?",
                               runner=runner_agent_team,
                               user_id=USER_ID,
                               session_id=SESSION_ID)
        await call_agent_async(query = "Thanks, bye!",
                               runner=runner_agent_team,
                               user_id=USER_ID,
                               session_id=SESSION_ID)

    await run_team_conversation()
else:
    print("\n⚠️ Skipping agent team conversation as the root agent was not successfully defined in the previous step.")
```

結果は以下のようになりました。

`Default value is not supported in function declaration schema for Google AI.`という警告が出ていますが、これはGoogle AIが関数のデフォルト値に対応していないことが原因のようです。

```text
--- Testing Agent Team Delegation ---
Session created: App='weather_tutorial_agent_team', User='user_1_agent_team', Session='session_001_agent_team'
Runner created for agent 'weather_agent_v2'.

>>> User Query: Hello there!
Default value is not supported in function declaration schema for Google AI.
Default value is not supported in function declaration schema for Google AI.
--- Tool: say_hello called with name: None ---
Default value is not supported in function declaration schema for Google AI.
<<< Agent Response: Hello, None!


>>> User Query: What is the weather in New York?
--- Tool: get_weather called for city: New York ---
<<< Agent Response: The weather in New York is sunny with a temperature of 25°C.


>>> User Query: Thanks, bye!
--- Tool: say_goodbye called ---
<<< Agent Response: Goodbye! Have a great day.
```

以下の様に`say_hello`関数からデフォルト値のある変数を削除することで、警告が出なくなりました。

```py
def say_hello(name: str) -> str:
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
```

このようにしてエージェントチームを実行した結果は以下のようになりました。

出力をみると、各クエリに対して正しくツールが使われており、サブエージェントが動作していることがわかります。

```text
--- Testing Agent Team Delegation ---
Session created: App='weather_tutorial_agent_team', User='user_1_agent_team', Session='session_001_agent_team'
Runner created for agent 'weather_agent_v2'.

>>> User Query: Hello there!
--- Tool: say_hello called with name: there ---
<<< Agent Response: Hello, there!


>>> User Query: What is the weather in New York?
--- Tool: get_weather called for city: New York ---
<<< Agent Response: The weather in New York is sunny with a temperature of 25°C.


>>> User Query: Thanks, bye!
--- Tool: say_goodbye called ---
<<< Agent Response: Goodbye! Have a great day.
```

## Stateを管理する
ここまでで実装してきたエージェントは過去の会話やユーザーの設定を保持していません。

ADKでは、ツールやエージェントが読み書きできるStateを使うことができます。

新しいノートブックで進めていきます。

### 環境変数の読み込み
APIキーを読み込んでおきます。
```py
from dotenv import load_dotenv
load_dotenv()
```

### 新たなセッションの作成
これまでと同様にセッションを作りますが、`state`を渡していることに注目してください。

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

### ツールの作成
天気の情報を取得するツールを定義します。

引数に`ToolContext`を受け取っていることに着目してください。ツール関数の最後のパラメータとして定義されている場合、ADKが自動的に挿入するようです。

また、`.state.get()`によってデフォルト値を指定しつつ読み込むことができます。これにより、エラーを回避することが可能です。

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

### エージェントを定義する
エージェントを定義します。

```py
from google.adk.agents import Agent
from google.adk.models.lite_llm import LiteLlm
from google.adk.runners import Runner

greeting_agent = None
try:
    greeting_agent = Agent(
        model=LiteLlm("gemini/gemini-2.0-flash"),
        name="greeting_agent",
        instruction="You are the Greeting Agent. Your ONLY task is to provide a friendly greeting using the 'say_hello' tool. Do nothing else.",
        description="Handles simple greetings and hellos using the 'say_hello' tool.",
        tools=[say_hello],
    )
    print(f"✅ Agent '{greeting_agent.name}' redefined.")
except Exception as e:
    print(f"❌ Could not redefine Greeting agent. Error: {e}")

farewell_agent = None
try:
    farewell_agent = Agent(
        model=LiteLlm("gemini/gemini-2.0-flash"),
        name="farewell_agent",
        instruction="You are the Farewell Agent. Your ONLY task is to provide a polite goodbye message using the 'say_goodbye' tool. Do not perform any other actions.",
        description="Handles simple farewells and goodbyes using the 'say_goodbye' tool.",
        tools=[say_goodbye],
    )
    print(f"✅ Agent '{farewell_agent.name}' redefined.")
except Exception as e:
    print(f"❌ Could not redefine Farewell agent. Error: {e}")

root_agent_stateful = None
runner_root_stateful = None

if greeting_agent and farewell_agent and 'get_weather_stateful' in globals():
    root_agent_stateful = Agent(
        name="weather_agent_v4_stateful", # New version name
        model=LiteLlm("gemini/gemini-2.0-flash"),
        description="Main agent: Provides weather (state-aware unit), delegates greetings/farewells, saves report to state.",
        instruction="You are the main Weather Agent. Your job is to provide weather using 'get_weather_stateful'. "
                    "The tool will format the temperature based on user preference stored in state. "
                    "Delegate simple greetings to 'greeting_agent' and farewells to 'farewell_agent'. "
                    "Handle only weather requests, greetings, and farewells.",
        tools=[get_weather_stateful], # Use the state-aware tool
        sub_agents=[greeting_agent, farewell_agent], # サブエージェント
        output_key="last_weather_report" # <<< Auto-save agent's final weather response
    )
    print(f"✅ Root Agent '{root_agent_stateful.name}' created using stateful tool and output_key.")

    runner_root_stateful = Runner(
        agent=root_agent_stateful,
        app_name=APP_NAME,
        session_service=session_service_stateful # Use the NEW stateful session service
    )
    print(f"✅ Runner created for stateful root agent '{runner_root_stateful.agent.name}' using stateful session service.")

else:
    print("❌ Cannot create stateful root agent. Prerequisites missing.")
    if not greeting_agent: print(" - greeting_agent definition missing.")
    if not farewell_agent: print(" - farewell_agent definition missing.")
    if 'get_weather_stateful' not in globals(): print(" - get_weather_stateful tool missing.")
```

### 呼び出して使う
あらかじめ前記の`call_agent_async`を定義しておきます。

{{< details summary="call_agent_async" >}}
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
{{< /details>}}

エージェントを実行する以下のプログラムを実行します。

```py
import asyncio

if 'runner_root_stateful' in globals() and runner_root_stateful:
    # The 'await' keywords INSIDE this function are necessary for async operations.
    async def run_stateful_conversation():
        print("\n--- Testing State: Temp Unit Conversion & output_key ---")

        # 1. 天気の確認 (Uses initial state: Celsius)
        print("--- Turn 1: Requesting weather in London (expect Celsius) ---")
        await call_agent_async(query= "What's the weather in London?",
                               runner=runner_root_stateful,
                               user_id=USER_ID_STATEFUL,
                               session_id=SESSION_ID_STATEFUL
                              )

        # 2. 手動でstateをFahrenheitに変更 - 直接ストレージを編集する
        print("\n--- Manually Updating State: Setting unit to Fahrenheit ---")
        try:
            # 永続的なストレージを使用する場合、通常は直接ストレージを操作せずに、エージェントのアクションや特定のサービスAPIを介して状態を更新します。
            # 内部ストレージにアクセスするのは、テスト目的でのみ行います。
            stored_session = session_service_stateful.sessions[APP_NAME][USER_ID_STATEFUL][SESSION_ID_STATEFUL]
            stored_session.state["user_preference_temperature_unit"] = "Fahrenheit"
            # Optional: タイムスタンプを更新する
            # import time
            # stored_session.last_update_time = time.time()
            print(f"--- Stored session state updated. Current 'user_preference_temperature_unit': {stored_session.state.get('user_preference_temperature_unit', 'Not Set')} ---") # Added .get for safety
        except KeyError:
            print(f"--- Error: Could not retrieve session '{SESSION_ID_STATEFUL}' from internal storage for user '{USER_ID_STATEFUL}' in app '{APP_NAME}' to update state. Check IDs and if session was created. ---")
        except Exception as e:
             print(f"--- Error updating internal session state: {e} ---")

        # 3. 再び天気を確認する (Fahrenheit表記になっていることを期待)
        # この操作はoutput_keyを介してlast_weather_reportを更新します。
        print("\n--- Turn 2: Requesting weather in New York (expect Fahrenheit) ---")
        await call_agent_async(query= "Tell me the weather in New York.",
                               runner=runner_root_stateful,
                               user_id=USER_ID_STATEFUL,
                               session_id=SESSION_ID_STATEFUL
                              )

        # 4. 通常の委任を実行
        # この操作はNYの天気情報でlast_weather_reportを上書きします。
        print("\n--- Turn 3: Sending a greeting ---")
        await call_agent_async(query= "Hi!",
                               runner=runner_root_stateful,
                               user_id=USER_ID_STATEFUL,
                               session_id=SESSION_ID_STATEFUL
                              )

    # 実行
    print("Attempting execution using 'await'...")
    await run_stateful_conversation()

    # 最終的なセッション状態を確認
    print("\n--- Inspecting Final Session State ---")
    final_session = session_service_stateful.get_session(app_name=APP_NAME,
                                                         user_id= USER_ID_STATEFUL,
                                                         session_id=SESSION_ID_STATEFUL)
    if final_session:
        # Use .get() for safer access to potentially missing keys
        print(f"Final Preference: {final_session.state.get('user_preference_temperature_unit', 'Not Set')}")
        print(f"Final Last Weather Report (from output_key): {final_session.state.get('last_weather_report', 'Not Set')}")
        print(f"Final Last City Checked (by tool): {final_session.state.get('last_city_checked_stateful', 'Not Set')}")
        # Print full state for detailed view
        # print(f"Full State Dict: {final_session.state.as_dict()}") # Use as_dict() for clarity
    else:
        print("\n❌ Error: Could not retrieve final session state.")

else:
    print("\n⚠️ Skipping state test conversation. Stateful root agent runner ('runner_root_stateful') is not available.")
```

実行した結果は以下のようになりました。おおむね期待通りの出力となりました。stateの値を基に温度が表示され、最終的なstateの値も問題なさそうです。

```text
Attempting execution using 'await'...

--- Testing State: Temp Unit Conversion & output_key ---
--- Turn 1: Requesting weather in London (expect Celsius) ---

>>> User Query: What's the weather in London?
--- Tool: get_weather_stateful called for London ---
--- Tool: Reading state 'user_preference_temperature_unit': Celsius ---
--- Tool: Generated report in Celsius. Result: {'status': 'success', 'report': 'The weather in London is cloudy with a temperature of 15°C.'} ---
--- Tool: Updated state 'last_city_checked_stateful': London ---
<<< Agent Response: The weather in London is cloudy with a temperature of 15°C.


--- Manually Updating State: Setting unit to Fahrenheit ---
--- Stored session state updated. Current 'user_preference_temperature_unit': Fahrenheit ---

--- Turn 2: Requesting weather in New York (expect Fahrenheit) ---

>>> User Query: Tell me the weather in New York.
--- Tool: get_weather_stateful called for New York ---
--- Tool: Reading state 'user_preference_temperature_unit': Fahrenheit ---
--- Tool: Generated report in Fahrenheit. Result: {'status': 'success', 'report': 'The weather in New york is sunny with a temperature of 77°F.'} ---
--- Tool: Updated state 'last_city_checked_stateful': New York ---
<<< Agent Response: The weather in New york is sunny with a temperature of 77°F.


--- Turn 3: Sending a greeting ---

>>> User Query: Hi!
Default value is not supported in function declaration schema for Google AI.
Default value is not supported in function declaration schema for Google AI.
--- Tool: say_hello called with name: there ---
<<< Agent Response: Hello, there!


--- Inspecting Final Session State ---
Final Preference: Fahrenheit
Final Last Weather Report (from output_key): Hello, there!

Final Last City Checked (by tool): New York
```

## おわりに
今回は複数のエージェントを使ったエージェントチームを作成し、stateの使い方も学びました。次回は`before_model_callback`の使い方などについて学びます。
