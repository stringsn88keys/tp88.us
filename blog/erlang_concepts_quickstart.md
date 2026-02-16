# Erlang Quick Reference for Experienced Programmers

## For more see:
* [Erlang Getting Started](https://www.erlang.org/doc/getting_started/users_guide)
* [Learn You Some Erlang](https://learnyousomeerlang.com/)

## Language Basics
- **Functional language**: No objects, no mutation. Functions transform data.
- **The BEAM VM**: Built for telecom — massive concurrency, fault tolerance, hot code reloading, soft real-time.
- **Immutable data**: Once bound, a variable cannot change. Single assignment.
- **Pattern matching**: Core mechanism for control flow, function dispatch, and destructuring.
- **Lightweight processes**: Not OS threads — millions of isolated BEAM processes, each with its own heap.
- **"Let it crash"**: Build reliability through supervision trees, not defensive coding.
- **Prolog heritage**: Syntax comes from Prolog — periods end statements, commas separate expressions, semicolons separate clauses.

## Syntax Essentials
```erlang
% This is a comment

% Statements end with a period (.)
% Expressions within a function are separated by commas (,)
% Clauses (in case, if, function heads) are separated by semicolons (;)

% Variables start with Uppercase
Name = "Tom".

% Atoms start with lowercase (like Ruby symbols)
ok.
error.
hello_world.
'atoms with spaces'.

% Everything is an expression — last expression in a function is the return value
```

## Data Types
```erlang
% Atoms
ok.
error.
true.                          % Booleans are atoms
false.

% Numbers
42.                            % Integer
3.14.                          % Float
16#FF.                         % Base-16 (255)
2#1010.                        % Base-2 (10)

% Strings (are actually lists of integers)
"hello".                       % [104, 101, 108, 108, 111]
[72, 101, 108, 108, 111].     % "Hello" — same thing

% Binaries (byte sequences — the efficient string)
<<"hello">>.                   % Binary string (preferred for text)
<<72, 101, 108, 108, 111>>.   % Same binary

% Tuples (fixed-size, contiguous memory)
{ok, "result"}.
{error, not_found}.
{user, "Tom", 30}.

% Lists (linked lists)
[1, 2, 3].
[Head | Tail] = [1, 2, 3].    % Head = 1, Tail = [2, 3]
[1 | [2 | [3 | []]]].         % How lists actually work

% Property lists (convention: list of {Key, Value} tuples)
[{name, "Tom"}, {age, 30}].
proplists:get_value(name, List).

% Maps (Erlang 17+)
#{name => "Tom", age => 30}.

% Records (compile-time syntactic sugar over tuples)
-record(user, {name, email, active = true}).
User = #user{name = "Tom", email = "tom@test.com"}.
User#user.name.                % Access field
```

## Pattern Matching
```erlang
% Variables are single-assignment — once bound, matching against them
X = 5.
X = 5.           % OK — matches
X = 6.           % ** badmatch error — X is already 5

% Tuple matching
{ok, Result} = {ok, 42}.          % Result = 42
{ok, Result} = {error, "fail"}.   % ** badmatch

% List matching
[H | T] = [1, 2, 3].              % H = 1, T = [2, 3]
[_, Second | _] = [a, b, c, d].   % Second = b, _ = don't care

% Map matching
#{name := Name} = #{name => "Tom", age => 30}.   % Name = "Tom"

% In function heads
area({circle, Radius}) -> math:pi() * Radius * Radius;
area({rectangle, W, H}) -> W * H;
area({square, Side}) -> Side * Side.

% In case expressions
case File:read("data.txt") of
    {ok, Contents} -> process(Contents);
    {error, enoent} -> io:format("File not found~n");
    {error, Reason} -> io:format("Error: ~p~n", [Reason])
end.
```

## Functions

### Module Functions
```erlang
-module(math_utils).
-export([add/2, divide/2]).     % Public functions (name/arity)

add(A, B) -> A + B.

divide(_, 0) -> {error, division_by_zero};
divide(A, B) -> {ok, A / B}.
```

### Function Clauses & Guards
```erlang
-module(greeting).
-export([greet/1]).

greet(Name) when is_binary(Name) -> <<"Hello, ", Name/binary>>;
greet(Name) when is_list(Name) -> "Hello, " ++ Name;
greet(Name) when is_atom(Name) -> greet(atom_to_list(Name)).
```

### Common Guards
```erlang
is_integer(X)
is_float(X)
is_number(X)
is_atom(X)
is_binary(X)       % Binary/string
is_list(X)
is_tuple(X)
is_map(X)
is_pid(X)
is_boolean(X)
X > 0
X >= 0 andalso X =< 100    % andalso/orelse (short-circuit)
length(List) > 0
map_size(Map) > 0
```

### Anonymous Functions (funs)
```erlang
Add = fun(A, B) -> A + B end.
Add(1, 2).                        % => 3

Double = fun(X) -> X * 2 end.
lists:map(Double, [1, 2, 3]).     % => [2, 4, 6]

% Inline
lists:filter(fun(X) -> X > 2 end, [1, 2, 3, 4]).  % => [3, 4]

% Capture module function
lists:map(fun erlang:abs/1, [-1, -2, 3]).  % => [1, 2, 3]

% Multi-clause fun
F = fun
    (0) -> zero;
    (N) when N > 0 -> positive;
    (_) -> negative
end.
```

## Modules
```erlang
-module(user).                     % Module name (must match filename)
-export([new/2, full_name/1]).     % Public API
-export_type([t/0]).               % Export types

-type t() :: #{
    name := binary(),
    email := binary(),
    active := boolean()
}.

-spec new(binary(), binary()) -> t().
new(Name, Email) ->
    #{name => Name, email => Email, active => true}.

-spec full_name(t()) -> binary().
full_name(#{name := Name}) -> Name.
```

### Module Attributes
```erlang
-module(config).
-author("Tom").
-vsn("1.0.0").

-define(MAX_RETRIES, 3).          % Macro (compile-time constant)
-define(LOG(Msg), io:format("~p: ~p~n", [?MODULE, Msg])).

retry(F) -> retry(F, ?MAX_RETRIES).
retry(_, 0) -> {error, max_retries};
retry(F, N) ->
    case F() of
        {ok, Result} -> {ok, Result};
        {error, _} -> retry(F, N - 1)
    end.
```

## Control Flow
```erlang
% case (pattern matching)
case lists:keyfind(name, 1, Props) of
    {name, Value} -> Value;
    false -> undefined
end.

% if (guard-based — no pattern matching, rarely used)
if
    X > 0 -> positive;
    X < 0 -> negative;
    true -> zero               % 'true' is the else clause
end.

% receive (message passing)
receive
    {msg, Text} -> io:format("Got: ~s~n", [Text]);
    stop -> ok
after
    5000 -> timeout            % Timeout in milliseconds
end.
```

### Why `case` Over `if`
`if` only supports guard expressions — no pattern matching. `case` is far more powerful and idiomatic. Most Erlang code uses `case` or function clause matching instead of `if`.

## List Operations
```erlang
% Common list functions
lists:map(fun(X) -> X * 2 end, [1, 2, 3]).          % => [2, 4, 6]
lists:filter(fun(X) -> X > 1 end, [1, 2, 3]).       % => [2, 3]
lists:foldl(fun(X, Acc) -> X + Acc end, 0, [1, 2, 3]).  % => 6
lists:foldr(fun(X, Acc) -> X + Acc end, 0, [1, 2, 3]).  % => 6
lists:any(fun(X) -> X > 2 end, [1, 2, 3]).          % => true
lists:all(fun(X) -> X > 0 end, [1, 2, 3]).          % => true
lists:member(2, [1, 2, 3]).                          % => true
lists:sort([3, 1, 2]).                               % => [1, 2, 3]
lists:reverse([1, 2, 3]).                            % => [3, 2, 1]
lists:flatten([[1, 2], [3, [4]]]).                   % => [1, 2, 3, 4]
lists:zip([1, 2], [a, b]).                           % => [{1, a}, {2, b}]
lists:nth(2, [a, b, c]).                             % => b (1-indexed)
lists:seq(1, 5).                                     % => [1, 2, 3, 4, 5]
length([1, 2, 3]).                                   % => 3

% List comprehensions
[X * 2 || X <- [1, 2, 3]].                          % => [2, 4, 6]
[X || X <- [1, 2, 3, 4], X rem 2 == 0].             % => [2, 4]
[{X, Y} || X <- [1, 2], Y <- [a, b]].               % => [{1,a},{1,b},{2,a},{2,b}]

% Cons operator
[1 | [2, 3]].                                        % => [1, 2, 3]

% String operations (strings are lists)
string:uppercase("hello").                            % => "HELLO"
string:split("a,b,c", ",").                          % => ["a", "b", "c"]
string:trim("  hello  ").                            % => "hello"
```

## Maps (Erlang 17+)
```erlang
% Create
Map = #{name => "Tom", age => 30}.

% Access
maps:get(name, Map).                  % => "Tom"
maps:get(missing, Map, default).      % => default
maps:find(name, Map).                 % => {ok, "Tom"}

% Update (key must exist for :=)
Map2 = Map#{age := 31}.              % Update existing key
Map3 = Map#{email => "tom@t.com"}.   % Add new key with =>

% Operations
maps:keys(Map).                       % => [age, name]
maps:values(Map).                     % => [30, "Tom"]
maps:merge(Map1, Map2).              % Merge (Map2 wins on conflict)
maps:remove(age, Map).               % Remove key
maps:is_key(name, Map).              % => true
maps:size(Map).                       % => 2
maps:to_list(Map).                    % => [{age, 30}, {name, "Tom"}]
maps:from_list([{a, 1}]).            % => #{a => 1}

% Pattern matching with maps
#{name := Name} = Map.               % Name = "Tom"

handle_request(#{method := get, path := Path}) ->
    serve_page(Path);
handle_request(#{method := post, body := Body}) ->
    process_body(Body).
```

## Processes & Concurrency
```erlang
% Spawn a process
Pid = spawn(fun() -> io:format("Hello from process~n") end).

% Spawn with module/function/args
Pid = spawn(module, function, [Arg1, Arg2]).

% Send message
Pid ! {self(), hello}.

% Receive message
receive
    {From, Msg} ->
        From ! {self(), received},
        io:format("Got: ~p~n", [Msg])
after
    5000 -> timeout
end.

% Self
self().                               % Current process PID

% Links (bidirectional — crash together)
link(Pid).
spawn_link(fun() -> error(boom) end).

% Monitors (unidirectional — get notified, don't crash)
Ref = monitor(process, Pid).
receive
    {'DOWN', Ref, process, Pid, Reason} ->
        io:format("Process died: ~p~n", [Reason])
end.

% Register process by name
register(my_server, Pid).
my_server ! {self(), hello}.          % Send by name

% Process info
is_process_alive(Pid).
process_info(Pid).
```

### Simple Client-Server Pattern
```erlang
-module(counter).
-export([start/0, increment/1, get/1]).

start() ->
    spawn(fun() -> loop(0) end).

increment(Pid) ->
    Pid ! increment.

get(Pid) ->
    Pid ! {get, self()},
    receive
        {count, N} -> N
    after
        1000 -> {error, timeout}
    end.

loop(Count) ->
    receive
        increment ->
            loop(Count + 1);
        {get, From} ->
            From ! {count, Count},
            loop(Count)
    end.
```

## OTP: gen_server
```erlang
-module(counter).
-behaviour(gen_server).

%% API
-export([start_link/0, increment/0, get_count/0]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2]).

%%% API %%%
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, 0, []).

increment() ->
    gen_server:cast(?MODULE, increment).

get_count() ->
    gen_server:call(?MODULE, get).

%%% Callbacks %%%
init(Initial) ->
    {ok, Initial}.

handle_cast(increment, Count) ->
    {noreply, Count + 1}.

handle_call(get, _From, Count) ->
    {reply, Count, Count}.
```

### gen_server Callback Return Values
| Callback | Return | Meaning |
|----------|--------|---------|
| `init/1` | `{ok, State}` | Start with State |
| `init/1` | `{stop, Reason}` | Don't start |
| `handle_call/3` | `{reply, Reply, NewState}` | Send Reply to caller |
| `handle_call/3` | `{noreply, NewState}` | Don't reply yet |
| `handle_cast/2` | `{noreply, NewState}` | Continue |
| `handle_cast/2` | `{stop, Reason, NewState}` | Shutdown |

## OTP: Supervisors
```erlang
-module(my_sup).
-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 5,           % Max 5 restarts
        period => 60              % Per 60 seconds
    },
    Children = [
        #{
            id => counter,
            start => {counter, start_link, []},
            restart => permanent,
            type => worker
        },
        #{
            id => logger,
            start => {my_logger, start_link, []},
            restart => transient,    % Only restart on abnormal exit
            type => worker
        }
    ],
    {ok, {SupFlags, Children}}.
```

### Supervision Strategies
| Strategy | Behavior |
|----------|----------|
| `one_for_one` | Only restart the failed child |
| `one_for_all` | Restart all children if one fails |
| `rest_for_one` | Restart the failed child and all started after it |
| `simple_one_for_one` | Dynamic children, all same spec (deprecated — use `simple_one_for_one` or DynamicSupervisor in Elixir) |

### Restart Types
| Type | When to Restart |
|------|----------------|
| `permanent` | Always restart (default) |
| `transient` | Only restart on abnormal exit |
| `temporary` | Never restart |

## Error Handling
```erlang
% Pattern matching on tagged tuples (preferred)
case file:read("data.txt") of
    {ok, Contents} -> process(Contents);
    {error, enoent} -> io:format("Not found~n");
    {error, Reason} -> io:format("Error: ~p~n", [Reason])
end.

% try/catch
try
    risky_operation()
catch
    throw:Reason -> io:format("Thrown: ~p~n", [Reason]);
    error:Reason -> io:format("Error: ~p~n", [Reason]);
    exit:Reason -> io:format("Exit: ~p~n", [Reason])
after
    cleanup()
end.

% Three kinds of exceptions
throw(my_reason).          % Deliberate non-local return (catchable)
error(bad_argument).       % Runtime error (usually a bug)
exit(shutdown).            % Process exit signal

% catch expression (older style — prefer try/catch)
Result = (catch some_function()).  % Returns {'EXIT', Reason} on error
```

### Exception Types
| Type | Meaning | Raised By |
|------|---------|-----------|
| `throw` | Expected, deliberate, non-local return | `throw(Reason)` |
| `error` | Runtime errors, bugs | `error(Reason)`, badmatch, badarith, etc. |
| `exit` | Process termination signal | `exit(Reason)` |

## ETS (Erlang Term Storage)
```erlang
% In-memory key-value storage shared between processes
Tab = ets:new(my_table, [set, named_table, public]).

ets:insert(my_table, {key, "value"}).
ets:lookup(my_table, key).            % => [{key, "value"}]
ets:delete(my_table, key).
ets:match(my_table, {'$1', "value"}). % => [[key]]

% Table types
% set       — unique keys (default)
% ordered_set — unique keys, sorted
% bag       — duplicate keys allowed, unique {key, value}
% duplicate_bag — fully duplicate entries allowed
```

## Binary & Bit Syntax
```erlang
% Binaries are byte sequences
Bin = <<"hello">>.
<<H, Rest/binary>> = <<"hello">>.    % H = 104, Rest = <<"ello">>

% Bit syntax for protocol parsing
<<Version:4, Type:4, Length:16, Payload/binary>> = Packet.

% Construct binaries
<<1:8, 256:16, "data"/binary>>.

% Binary comprehensions
<< <<(X*2)>> || <<X>> <= <<1, 2, 3>> >>.  % => <<2, 4, 6>>
```

## Common Built-in Functions (BIFs)
```erlang
% Type conversions
list_to_binary("hello").              % => <<"hello">>
binary_to_list(<<"hello">>).          % => "hello"
integer_to_list(42).                  % => "42"
list_to_integer("42").                % => 42
atom_to_list(hello).                  % => "hello"
list_to_atom("hello").                % => hello
term_to_binary(Any).                  % Serialize any term
binary_to_term(Bin).                  % Deserialize

% Tuple operations
tuple_size({a, b, c}).                % => 3
element(2, {a, b, c}).                % => b (1-indexed)
setelement(2, {a, b, c}, x).         % => {a, x, c}

% I/O
io:format("Hello ~s, you are ~p years old~n", ["Tom", 30]).
% ~s = string, ~p = pretty-print any term, ~w = write, ~n = newline
% ~B = integer (base 10), ~.2f = float with 2 decimals
```

## The Shell (erl)
```erlang
% Start
erl                                    % Start Erlang shell
erl -pa ebin                           % Add path to code search
erl -name node@host                    % Start distributed node

% Shell commands
help().                                % Show help
q().                                   % Quit
c(module).                             % Compile module
l(module).                             % Load/reload module
m(module).                             % Module info
f().                                   % Forget all bindings
f(X).                                  % Forget binding for X
rr(module).                            % Read record definitions
```

## Build Tools
```bash
# rebar3 (standard build tool)
rebar3 new app myapp                   # Create new application
rebar3 new release myrelease           # Create new release project
rebar3 compile                         # Compile
rebar3 eunit                           # Run EUnit tests
rebar3 ct                              # Run Common Test suites
rebar3 shell                           # Start shell with project loaded
rebar3 dialyzer                        # Static type analysis
rebar3 release                         # Build release

# erlc (compiler)
erlc module.erl                        # Compile single module
erlc -o ebin src/*.erl                 # Compile to output directory
```

## Dependencies (rebar.config)
```erlang
% rebar.config
{erl_opts, [debug_info]}.

{deps, [
    {cowboy, "2.10.0"},                % Hex package
    {jsx, {git, "https://github.com/talentdeficit/jsx.git", {tag, "v3.1.0"}}}
]}.

{profiles, [
    {test, [
        {deps, [{meck, "0.9.2"}]}     % Test-only dependency
    ]}
]}.
```

## Key Differences from Other Languages
- Variables are Uppercase, atoms are lowercase — easy to confuse at first
- Single assignment — once a variable is bound, it cannot be rebound
- Statements end with periods (`.`), not semicolons
- Semicolons (`;`) separate clauses, commas (`,`) separate expressions
- Strings are lists of integers — use binaries (`<<"hello">>`) for real text handling
- No string interpolation — use `io_lib:format/2` or `lists:concat/1`
- No objects, no classes — modules and functions only
- Arity is part of the function identity: `add/2` and `add/3` are different functions
- No exceptions for flow control — use tagged tuples (`{ok, Val}` / `{error, Reason}`)
- The shell does NOT support defining modules — only expressions (use files and `c(module)`)
- **Erlang is NOT Elixir**: Elixir runs on the same VM and can call Erlang directly, but they have different syntax, conventions, and tooling

That's the essential Erlang. The rest is mastering OTP patterns, understanding the BEAM's scheduling and memory model, and exploring the extensive standard library.
