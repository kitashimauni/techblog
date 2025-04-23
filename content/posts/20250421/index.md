+++
title = 'Agent Development Kitに触ってみる #2'
date = '2025-04-21T22:39:39+09:00'
draft = true
summary = 'エージェントチームなどを実装します'
tags = ['ADK', 'マルチエージェントシステム']
+++

今回はADKのチュートリアルの3章以降をやっていきます。

{{< linkcard "https://google.github.io/adk-docs/get-started/tutorial/" >}}

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

## 新たなセッションを作る

