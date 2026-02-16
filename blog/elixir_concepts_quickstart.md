# Elixir Quick Reference for Experienced Programmers

## For more see:
* [Elixir Getting Started Guide](https://elixir-lang.org/getting-started/introduction.html)
* [Elixir School](https://elixirschool.com/)

## Language Basics
- **Functional language**: No objects, no mutation. Data in, data out.
- **Runs on the BEAM**: Erlang VM — battle-tested concurrency, fault tolerance, hot code reloading.
- **Immutable data**: Variables can be rebound, but data structures are never mutated.
- **Pattern matching everywhere**: `=` is match, not assignment. Destructuring is the norm.
- **Processes are cheap**: Not OS processes — lightweight BEAM processes (millions possible).
- **"Let it crash"**: Supervisors restart failed processes. Don't program defensively — let things fail and recover.

## Data Types
```elixir
# Atoms (like Ruby symbols)
:ok
:error
true                      # true/false/nil are atoms

# Numbers
42                        # Integer
3.14                      # Float

# Strings (UTF-8 binaries)
"hello"                   # Double quotes = string (binary)
'hello'                   # Single quotes = charlist (Erlang compat, rarely used)

# Tuples (fixed-size, contiguous memory)
{:ok, "result"}
{:error, "not found"}

# Lists (linked lists)
[1, 2, 3]
[head | tail] = [1, 2, 3]  # head = 1, tail = [2, 3]

# Keyword lists (list of {atom, value} tuples)
[name: "Tom", age: 30]   # Same as [{:name, "Tom"}, {:age, 30}]
# Allows duplicate keys, ordered — used for options

# Maps (key-value, any key type)
%{name: "Tom", age: 30}  # Atom keys (shorthand)
%{"name" => "Tom"}        # String keys

# Structs (typed maps with compile-time checks)
defmodule User do
  defstruct [:name, :email, active: true]
end
%User{name: "Tom", email: "tom@example.com"}

# Ranges
1..10
1..10//2                  # Step of 2 (Elixir 1.12+)
```

## Pattern Matching
```elixir
# The = operator is match, not assignment
{:ok, result} = {:ok, 42}    # result = 42
{:ok, result} = {:error, ""}  # ** (MatchError)

# In function heads
def process({:ok, data}), do: handle_data(data)
def process({:error, reason}), do: log_error(reason)

# In case
case HTTP.get(url) do
  {:ok, %{status: 200, body: body}} -> parse(body)
  {:ok, %{status: 404}} -> :not_found
  {:error, reason} -> {:error, reason}
end

# Pin operator (match against existing value, don't rebind)
x = 1
^x = 1    # Matches
^x = 2    # ** (MatchError)

# Destructuring maps
%{name: name, age: age} = %{name: "Tom", age: 30, extra: "ignored"}
# name = "Tom", age = 30

# Destructuring in function params
def greet(%User{name: name}), do: "Hello, #{name}"
```

## Functions

### Named Functions (in modules)
```elixir
defmodule Math do
  def add(a, b), do: a + b           # Public

  defp validate(n) when n > 0, do: n  # Private
  defp validate(_), do: raise "must be positive"

  # Multi-clause with guards
  def divide(_, 0), do: {:error, :division_by_zero}
  def divide(a, b) when is_number(a) and is_number(b), do: {:ok, a / b}

  # Default arguments
  def increment(n, step \\ 1), do: n + step
end
```

### Anonymous Functions
```elixir
add = fn a, b -> a + b end
add.(1, 2)                    # => 3 (note the dot)

# Shorthand capture syntax
add = &(&1 + &2)
add.(1, 2)                    # => 3

double = &(&1 * 2)
Enum.map([1, 2, 3], double)  # => [2, 4, 6]

# Capture named function
Enum.map([1, 2, 3], &Math.add(&1, 1))
upcase = &String.upcase/1     # Capture with arity
Enum.map(["a", "b"], upcase) # => ["A", "B"]
```

### Key Distinction: Named vs Anonymous
```elixir
# Named function - called without dot
Math.add(1, 2)

# Anonymous function - called WITH dot
add = fn a, b -> a + b end
add.(1, 2)
```

## The Pipe Operator
```elixir
# Without pipe (nested calls)
String.split(String.trim(String.downcase("  HELLO WORLD  ")))

# With pipe (left-to-right, result becomes first arg)
"  HELLO WORLD  "
|> String.downcase()
|> String.trim()
|> String.split()
# => ["hello", "world"]

# Common pattern with Enum
users
|> Enum.filter(&(&1.active))
|> Enum.map(& &1.email)
|> Enum.sort()
|> Enum.take(10)
```

## Control Flow
```elixir
# if/else (rare in idiomatic Elixir — prefer pattern matching)
if condition do
  "yes"
else
  "no"
end

# unless
unless logged_in?, do: redirect(conn, to: "/login")

# cond (first truthy match)
cond do
  age < 13 -> "child"
  age < 18 -> "teenager"
  true -> "adult"         # Default clause
end

# case (pattern matching)
case value do
  {:ok, result} -> result
  {:error, :not_found} -> nil
  {:error, reason} -> raise reason
end

# with (happy path chaining — early exit on mismatch)
with {:ok, user} <- fetch_user(id),
     {:ok, profile} <- fetch_profile(user),
     {:ok, avatar} <- fetch_avatar(profile) do
  {:ok, %{user: user, avatar: avatar}}
else
  {:error, reason} -> {:error, reason}
end
```

## Modules & Behaviours
```elixir
defmodule Greeter do
  @moduledoc "Handles greetings"     # Module documentation
  @greeting "Hello"                   # Module attribute (compile-time constant)

  @doc "Greets a person by name"
  def greet(name), do: "#{@greeting}, #{name}!"
end

# Behaviours (like interfaces)
defmodule Parser do
  @callback parse(String.t()) :: {:ok, term()} | {:error, String.t()}
end

defmodule JSONParser do
  @behaviour Parser

  @impl Parser
  def parse(str), do: Jason.decode(str)
end
```

### use, import, alias, require
```elixir
defmodule MyModule do
  alias MyApp.Accounts.User         # User instead of MyApp.Accounts.User
  alias MyApp.Accounts.{User, Role} # Multiple aliases

  import Enum, only: [map: 2, filter: 2]  # Bring functions into scope
  import Enum, except: [split: 2]

  require Logger                    # Needed for macros (compile-time)

  use GenServer                     # Calls GenServer.__using__/1 macro
  # 'use' injects code — it's a macro that typically adds functions/behaviour
end
```

## Enum & Stream
```elixir
# Enum (eager — processes entire collection)
Enum.map([1, 2, 3], &(&1 * 2))              # => [2, 4, 6]
Enum.filter([1, 2, 3], &(&1 > 1))           # => [2, 3]
Enum.reject([1, 2, 3], &(&1 > 1))           # => [1]
Enum.reduce([1, 2, 3], 0, &(&1 + &2))       # => 6
Enum.any?([1, 2, 3], &(&1 > 2))             # => true
Enum.all?([1, 2, 3], &(&1 > 0))             # => true
Enum.find([1, 2, 3], &(&1 > 1))             # => 2
Enum.count([1, 2, 3])                        # => 3
Enum.sort_by(users, & &1.name)
Enum.group_by(users, & &1.role)
Enum.zip([1, 2], [:a, :b])                  # => [{1, :a}, {2, :b}]
Enum.flat_map([[1, 2], [3]], &Function.identity/1) # => [1, 2, 3]
Enum.chunk_every([1, 2, 3, 4, 5], 2)        # => [[1, 2], [3, 4], [5]]
Enum.each(items, &IO.inspect/1)              # Side effects (returns :ok)

# Stream (lazy — computes on demand)
1..1_000_000
|> Stream.filter(&(rem(&1, 2) == 0))
|> Stream.map(&(&1 * 2))
|> Enum.take(5)                              # Only computes 5 values
# => [4, 8, 12, 16, 20]

# Infinite streams
Stream.iterate(0, &(&1 + 1))                # 0, 1, 2, 3, ...
Stream.cycle([1, 2, 3])                      # 1, 2, 3, 1, 2, 3, ...
Stream.repeatedly(fn -> :rand.uniform() end) # Random numbers forever
```

## Maps & Structs
```elixir
# Map operations
map = %{name: "Tom", age: 30}
map.name                              # => "Tom" (atom key access)
map[:name]                            # => "Tom" (bracket access, returns nil for missing)
Map.get(map, :name)                   # => "Tom"
Map.get(map, :missing, "default")     # => "default"
Map.put(map, :email, "tom@test.com")  # Returns new map
Map.merge(map, %{age: 31})           # Returns new map
Map.delete(map, :age)                 # Returns new map
Map.keys(map)                         # => [:age, :name]
Map.values(map)                       # => [30, "Tom"]

# Update syntax (key must exist)
%{map | age: 31}                      # => %{name: "Tom", age: 31}
%{map | missing: "x"}                 # ** (KeyError)

# Nested access/update
users = %{tom: %{age: 30}}
get_in(users, [:tom, :age])           # => 30
put_in(users, [:tom, :age], 31)       # => %{tom: %{age: 31}}
update_in(users, [:tom, :age], &(&1 + 1))

# Structs
defmodule User do
  defstruct [:name, :email, active: true]

  def new(name, email) do
    %User{name: name, email: email}
  end
end

user = %User{name: "Tom"}
%User{name: name} = user              # Pattern match on struct type
user.active                            # => true
%{user | active: false}                # Update (same syntax as maps)
```

## Processes & Concurrency
```elixir
# Spawn a process
pid = spawn(fn -> IO.puts("Hello from process") end)

# Send and receive messages
pid = spawn(fn ->
  receive do
    {:greet, name} -> IO.puts("Hello, #{name}")
  end
end)

send(pid, {:greet, "Tom"})

# Self
self()                                # Current process PID

# Process links (crash together)
spawn_link(fn -> raise "boom" end)   # Crashes the caller too

# Monitors (notification on crash, no crash propagation)
ref = Process.monitor(pid)
receive do
  {:DOWN, ^ref, :process, ^pid, reason} -> IO.puts("Process died: #{reason}")
end

# Tasks (high-level async)
task = Task.async(fn -> expensive_work() end)
result = Task.await(task)             # Blocks until done (5s default timeout)

# Multiple tasks
tasks = Enum.map(urls, &Task.async(fn -> HTTP.get(&1) end))
results = Task.await_many(tasks)
```

## GenServer (Generic Server)
```elixir
defmodule Counter do
  use GenServer

  # Client API
  def start_link(initial \\ 0) do
    GenServer.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def increment, do: GenServer.cast(__MODULE__, :increment)
  def get_count, do: GenServer.call(__MODULE__, :get)

  # Server callbacks
  @impl true
  def init(initial), do: {:ok, initial}

  @impl true
  def handle_cast(:increment, count), do: {:noreply, count + 1}

  @impl true
  def handle_call(:get, _from, count), do: {:reply, count, count}
end

# Usage
{:ok, _pid} = Counter.start_link(0)
Counter.increment()
Counter.get_count()   # => 1
```

### GenServer Call vs Cast
| | `call` | `cast` |
|---|---|---|
| Synchronous? | Yes (blocks caller) | No (fire-and-forget) |
| Returns | Reply value | `:ok` |
| Callback | `handle_call/3` | `handle_cast/2` |
| Use when | You need the result | You don't need a response |

## Supervisors
```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Counter, 0},                           # Child spec
      {MyApp.Worker, []},
      {Task.Supervisor, name: MyApp.TaskSupervisor},
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### Supervision Strategies
| Strategy | Behavior |
|----------|----------|
| `:one_for_one` | Only restart the failed child |
| `:one_for_all` | Restart all children if one fails |
| `:rest_for_one` | Restart the failed child and all children started after it |

## Error Handling
```elixir
# Pattern matching on tagged tuples (preferred)
case File.read("data.txt") do
  {:ok, contents} -> process(contents)
  {:error, :enoent} -> IO.puts("File not found")
  {:error, reason} -> IO.puts("Error: #{reason}")
end

# try/rescue (rare — for unexpected errors)
try do
  risky_operation()
rescue
  e in RuntimeError -> IO.puts("Runtime error: #{e.message}")
  ArgumentError -> IO.puts("Bad argument")
after
  cleanup()
end

# raise / throw
raise "something went wrong"
raise ArgumentError, message: "bad value"

# Bang functions (raise on error)
File.read!("data.txt")               # Returns contents or raises
File.read("data.txt")                # Returns {:ok, contents} or {:error, reason}
```

### Convention: `!` Functions
```elixir
# Functions often come in pairs:
File.read("f.txt")      # => {:ok, "..."} or {:error, reason}
File.read!("f.txt")     # => "..." or raises File.Error

Enum.fetch([1,2], 0)    # => {:ok, 1}
Enum.fetch!([1,2], 0)   # => 1

# Use non-bang when you want to handle the error
# Use bang when failure is unexpected / should crash
```

## Strings & Sigils
```elixir
# Interpolation
"Hello, #{name}"

# Multiline
"""
Hello,
World
"""

# Sigils
~s(string with "quotes")             # String
~r/regex pattern/                      # Regex
~w(foo bar baz)                        # Word list => ["foo", "bar", "baz"]
~w(foo bar baz)a                       # Atom word list => [:foo, :bar, :baz]
~D[2024-01-15]                         # Date
~T[13:45:00]                           # Time
~U[2024-01-15 13:45:00Z]              # UTC DateTime

# String functions
String.length("hello")                 # => 5
String.upcase("hello")                 # => "HELLO"
String.downcase("HELLO")              # => "hello"
String.trim("  hello  ")              # => "hello"
String.split("a,b,c", ",")           # => ["a", "b", "c"]
String.replace("hello", "l", "r")    # => "herro"
String.starts_with?("hello", "he")   # => true
String.contains?("hello", "ell")     # => true
String.to_integer("42")              # => 42
```

## Comprehensions
```elixir
# for (not a loop — returns a list by default)
for x <- [1, 2, 3], do: x * 2
# => [2, 4, 6]

# With filter
for x <- 1..10, rem(x, 2) == 0, do: x
# => [2, 4, 6, 8, 10]

# Multiple generators (nested)
for x <- [1, 2], y <- [:a, :b], do: {x, y}
# => [{1, :a}, {1, :b}, {2, :a}, {2, :b}]

# Into (collect into different types)
for {k, v} <- %{a: 1, b: 2}, into: %{}, do: {k, v * 2}
# => %{a: 2, b: 4}

# Pattern matching in generators
for {:ok, val} <- [{:ok, 1}, {:error, 2}, {:ok, 3}], do: val
# => [1, 3] (errors silently skipped)
```

## Protocols (Polymorphism)
```elixir
# Define a protocol
defprotocol Printable do
  @doc "Converts data to a printable string"
  def to_str(data)
end

# Implement for different types
defimpl Printable, for: Integer do
  def to_str(n), do: Integer.to_string(n)
end

defimpl Printable, for: User do
  def to_str(user), do: user.name
end

# Usage
Printable.to_str(42)                  # => "42"
Printable.to_str(%User{name: "Tom"})  # => "Tom"
```

## Testing (ExUnit)
```elixir
# test/user_test.exs
defmodule UserTest do
  use ExUnit.Case, async: true        # async: true runs in parallel

  describe "full_name/1" do
    test "returns first and last name" do
      user = %User{first: "Tom", last: "Powell"}
      assert User.full_name(user) == "Tom Powell"
    end

    test "handles missing last name" do
      user = %User{first: "Tom", last: nil}
      assert User.full_name(user) == "Tom"
    end
  end

  test "raises on invalid input" do
    assert_raise ArgumentError, fn ->
      User.full_name(nil)
    end
  end
end
```

### Common Assertions
```elixir
assert value                           # Truthy
refute value                           # Falsy
assert x == y                          # Equality
assert x =~ ~r/pattern/               # Regex match
assert_raise RuntimeError, fn -> ... end
assert_receive {:msg, _}, 500         # Process message (with timeout)
refute_receive {:msg, _}
```

## Mix (Build Tool)
```bash
mix new myapp                          # Create new project
mix new myapp --sup                    # With supervision tree
mix deps.get                           # Install dependencies
mix compile                            # Compile project
mix test                               # Run tests
mix test test/user_test.exs            # Run specific file
mix test test/user_test.exs:15         # Run specific line
mix format                             # Auto-format code
mix hex.info package_name              # Package info
iex -S mix                             # Interactive shell with project loaded
```

## Dependencies (mix.exs)
```elixir
# mix.exs
defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_app,
      version: "0.1.0",
      elixir: "~> 1.15",
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MyApp.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},              # JSON parser
      {:httpoison, "~> 2.0"},          # HTTP client
      {:ecto, "~> 3.10"},              # Database wrapper
      {:ex_machina, "~> 2.7", only: :test},  # Test factories
    ]
  end
end
```

## Key Differences from Other Languages
- No objects, no classes — modules and functions only
- No mutation — all data is immutable, functions return new data
- `=` is pattern matching, not assignment
- Anonymous functions use `.()` to call: `func.(args)`
- No `for` loops in the traditional sense — use `Enum`, `Stream`, or comprehensions
- No `null` — use `nil`, and tagged tuples (`{:ok, val}` / `{:error, reason}`) for control flow
- Processes are not threads — they're isolated, share nothing, communicate via messages
- "Let it crash" — don't code defensively, let supervisors handle failures
- Tail-call optimization is real — recursion replaces loops
- **Elixir is NOT Erlang**: Elixir compiles to BEAM bytecode and can call Erlang directly, but has its own syntax, tooling, and standard library

That's the essential Elixir. The rest is exploring OTP patterns, the rich standard library, and the ecosystem of Hex packages.
