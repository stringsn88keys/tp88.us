# Phoenix Quick Reference for Experienced Programmers

## For more see:
* [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
* [Phoenix HexDocs](https://hexdocs.pm/phoenix/)

## What is Phoenix?
- **Web framework for Elixir**: Like Rails for Ruby, but built on the BEAM VM.
- **Real-time first**: Channels/LiveView built in — WebSockets are a first-class citizen.
- **Functional MVC**: Controllers are just modules with functions. No inheritance, no instance variables.
- **Speed**: Microsecond response times. The BEAM handles millions of concurrent connections.

## Architecture Overview
- **Endpoint**: Entry point. Plugs for parsing, static files, session, router.
- **Router**: Maps HTTP verbs + paths to controller actions. Pipelines group middleware.
- **Controllers**: Receive conn (connection struct), call context functions, render response.
- **Views / Components**: HEEx templates. Function components. No instance variables — explicit assigns.
- **Contexts**: Business logic boundary modules (e.g., `Accounts`, `Blog`). Keep controllers thin.
- **Schemas**: Ecto schemas map to database tables. Changesets handle validation and casting.

## Convention Over Configuration
- `lib/my_app_web/` — Web layer (controllers, components, router)
- `lib/my_app/` — Business logic (contexts, schemas)
- Module names match file paths: `lib/my_app_web/controllers/user_controller.ex` → `MyAppWeb.UserController`
- Schema `User` → table `users`

## Directory Layout
```
lib/
  my_app/                        # Business logic
    accounts/                    # Context directory
      user.ex                    # Ecto schema
    accounts.ex                  # Context module (public API)
    repo.ex                      # Database repo
    application.ex               # Supervision tree
  my_app_web/                    # Web layer
    controllers/
      user_controller.ex
      user_html.ex               # View module
      user_html/
        index.html.heex          # Template
        show.html.heex
    components/
      core_components.ex         # Shared UI components
      layouts.ex                 # Layout components
      layouts/
        app.html.heex
        root.html.heex
    live/                        # LiveView modules
      user_live/
        index.ex
        show.ex
    router.ex
    endpoint.ex
config/
  config.exs                     # Shared config
  dev.exs                        # Dev config
  prod.exs                       # Prod config
  runtime.exs                    # Runtime config (env vars)
priv/
  repo/migrations/               # Database migrations
  static/                        # Static assets
test/
  my_app/                        # Context tests
  my_app_web/                    # Web layer tests
  support/                       # Test helpers
```

## Router
```elixir
# lib/my_app_web/router.ex
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MyAppWeb do
    pipe_through :browser

    get "/", PageController, :home
    resources "/users", UserController         # 7 RESTful routes
    resources "/posts", PostController, only: [:index, :show]
    resources "/posts", PostController, except: [:delete]

    # Nested resources
    resources "/posts", PostController do
      resources "/comments", CommentController
    end

    # LiveView routes
    live "/dashboard", DashboardLive
    live "/users/:id/edit", UserLive.Edit
  end

  scope "/api", MyAppWeb.API, as: :api do
    pipe_through :api

    resources "/users", UserController, except: [:new, :edit]
  end
end
```

### RESTful Routes from `resources`
```elixir
resources "/posts", PostController
```

| HTTP Verb | Path | Controller Action | Helper |
|-----------|------|-------------------|--------|
| GET | /posts | :index | ~p"/posts" |
| GET | /posts/new | :new | ~p"/posts/new" |
| POST | /posts | :create | ~p"/posts" |
| GET | /posts/:id | :show | ~p"/posts/#{post}" |
| GET | /posts/:id/edit | :edit | ~p"/posts/#{post}/edit" |
| PATCH/PUT | /posts/:id | :update | ~p"/posts/#{post}" |
| DELETE | /posts/:id | :delete | ~p"/posts/#{post}" |

## Plug (Middleware)
```elixir
# Plug is the specification for composable web middleware
# Every request is a %Plug.Conn{} struct passed through plugs

# Function plug
def authenticate(conn, _opts) do
  if get_session(conn, :user_id) do
    conn
  else
    conn
    |> put_flash(:error, "You must be logged in")
    |> redirect(to: ~p"/login")
    |> halt()              # Stop the plug pipeline
  end
end

# Module plug
defmodule MyAppWeb.Plugs.Authenticate do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> put_view(MyAppWeb.ErrorJSON)
      |> render("401.json")
      |> halt()
    end
  end
end

# Use in router pipeline
pipeline :authenticated do
  plug MyAppWeb.Plugs.Authenticate
end
```

## Controllers
```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller

  alias MyApp.Accounts

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, :index, users: users)
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, :show, user: user)
  end

  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created.")
        |> redirect(to: ~p"/users/#{user}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated.")
        |> redirect(to: ~p"/users/#{user}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, user: user, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    {:ok, _user} = Accounts.delete_user(user)

    conn
    |> put_flash(:info, "User deleted.")
    |> redirect(to: ~p"/users")
  end
end
```

### JSON Controllers
```elixir
defmodule MyAppWeb.API.UserController do
  use MyAppWeb, :controller

  alias MyApp.Accounts

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, :index, users: users)
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, :show, user: user)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", ~p"/api/users/#{user}")
        |> render(:show, user: user)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(MyAppWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)
    end
  end
end

# JSON view
defmodule MyAppWeb.API.UserJSON do
  def index(%{users: users}) do
    %{data: for(user <- users, do: data(user))}
  end

  def show(%{user: user}) do
    %{data: data(user)}
  end

  defp data(user) do
    %{
      id: user.id,
      name: user.name,
      email: user.email
    }
  end
end
```

## Contexts (Business Logic Layer)
```elixir
# lib/my_app/accounts.ex
defmodule MyApp.Accounts do
  alias MyApp.Repo
  alias MyApp.Accounts.User

  def list_users do
    Repo.all(User)
  end

  def get_user!(id) do
    Repo.get!(User, id)
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end
```

### Why Contexts?
- Decouple web layer from business logic
- Controllers don't touch `Repo` directly
- Group related schemas and operations (e.g., `Accounts` manages `User`, `Credential`, `Token`)
- Makes code testable without the web layer

## Ecto Schemas & Changesets
```elixir
# lib/my_app/accounts/user.ex
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :age, :integer
    field :active, :boolean, default: true
    field :role, Ecto.Enum, values: [:user, :admin]

    has_many :posts, MyApp.Blog.Post
    belongs_to :organization, MyApp.Organizations.Org
    many_to_many :tags, MyApp.Tags.Tag, join_through: "users_tags"

    timestamps()                       # inserted_at, updated_at
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :age, :role])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:name, min: 2, max: 100)
    |> validate_number(:age, greater_than: 0)
    |> validate_inclusion(:role, [:user, :admin])
    |> unique_constraint(:email)
  end
end
```

### Changeset Flow
```elixir
# Changesets track changes, validations, and constraints
attrs = %{"name" => "Tom", "email" => "tom@test.com"}

changeset = User.changeset(%User{}, attrs)
changeset.valid?     # => true
changeset.changes    # => %{name: "Tom", email: "tom@test.com"}
changeset.errors     # => []

# Invalid changeset
bad = User.changeset(%User{}, %{"name" => ""})
bad.valid?           # => false
bad.errors           # => [name: {"can't be blank", [validation: :required]}]
```

## Ecto Queries
```elixir
import Ecto.Query

# Basic queries
Repo.all(User)
Repo.get(User, 1)                              # nil if not found
Repo.get!(User, 1)                             # raises if not found
Repo.get_by(User, email: "tom@test.com")
Repo.one(from u in User, where: u.id == 1)

# Keyword syntax
from u in User,
  where: u.active == true,
  where: u.age > 18,
  order_by: [asc: u.name],
  limit: 10,
  select: u

# Pipe syntax
User
|> where([u], u.active == true)
|> where([u], u.age > 18)
|> order_by([u], asc: u.name)
|> limit(10)
|> Repo.all()

# Preloading associations
Repo.all(from u in User, preload: [:posts])
user |> Repo.preload(:posts)

# Aggregates
Repo.aggregate(User, :count)
from(u in User, select: avg(u.age)) |> Repo.one()

# Fragments (raw SQL)
from u in User, where: fragment("lower(?) = ?", u.email, ^email)

# Insert / Update / Delete
Repo.insert(%User{name: "Tom"})
Repo.update(changeset)
Repo.delete(user)
```

## Migrations
```elixir
# priv/repo/migrations/20240115120000_create_users.exs
defmodule MyApp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :age, :integer
      add :active, :boolean, default: true
      add :organization_id, references(:organizations, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:users, [:email])
    create index(:users, [:organization_id])
  end
end
```

```bash
mix ecto.gen.migration create_users    # Generate migration
mix ecto.migrate                       # Run migrations
mix ecto.rollback                      # Undo last migration
mix ecto.rollback --step 3             # Undo last 3
mix ecto.reset                         # Drop, create, migrate
mix ecto.setup                         # Create, migrate, seed
```

## Templates & Components (HEEx)
```heex
<%# lib/my_app_web/controllers/user_html/index.html.heex %>

<.header>
  Users
  <:actions>
    <.link href={~p"/users/new"}>New User</.link>
  </:actions>
</.header>

<.table id="users" rows={@users}>
  <:col :let={user} label="Name"><%= user.name %></:col>
  <:col :let={user} label="Email"><%= user.email %></:col>
  <:action :let={user}>
    <.link href={~p"/users/#{user}"}>Show</.link>
    <.link href={~p"/users/#{user}/edit"}>Edit</.link>
  </:action>
</.table>
```

### Function Components
```elixir
# lib/my_app_web/components/core_components.ex
defmodule MyAppWeb.CoreComponents do
  use Phoenix.Component

  attr :type, :string, default: "info"
  attr :message, :string, required: true

  def flash(assigns) do
    ~H"""
    <div class={"alert alert-#{@type}"}>
      <%= @message %>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :rows, :list, required: true
  slot :col, required: true do
    attr :label, :string
  end
  slot :action

  def table(assigns) do
    ~H"""
    <table id={@id}>
      <thead>
        <tr>
          <th :for={col <- @col}><%= col[:label] %></th>
          <th :if={@action != []}>Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr :for={row <- @rows}>
          <td :for={col <- @col}><%= render_slot(col, row) %></td>
          <td :if={@action != []}>
            <%= for action <- @action do %>
              <%= render_slot(action, row) %>
            <% end %>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end
end
```

### Template Syntax Summary
| Syntax | Purpose |
|--------|---------|
| `<%= expr %>` | Output expression (escaped) |
| `<% expr %>` | Execute expression (no output) |
| `{@assign}` | Access assign in attributes |
| `<.component />` | Call function component |
| `:let={var}` | Bind slot variable |
| `:for={x <- list}` | Iterate (comprehension) |
| `:if={condition}` | Conditional rendering |
| `<:slot_name>` | Named slot content |
| `~p"/path"` | Verified route |

## LiveView
```elixir
# lib/my_app_web/live/counter_live.ex
defmodule MyAppWeb.CounterLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def handle_event("decrement", _params, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Count: <%= @count %></h1>
      <button phx-click="increment">+</button>
      <button phx-click="decrement">-</button>
    </div>
    """
  end
end
```

### LiveView Lifecycle
1. `mount/3` — Initial state (runs twice: once for static HTML, once for WebSocket)
2. `handle_params/3` — URL changes (navigation)
3. `handle_event/3` — User interactions (clicks, form submits)
4. `handle_info/2` — Server-side messages (PubSub, process messages)
5. `render/1` — Returns HEEx template (re-runs on every assign change, diffs sent over WebSocket)

### Common LiveView Patterns
```elixir
# Form handling
def handle_event("validate", %{"user" => params}, socket) do
  changeset =
    %User{}
    |> User.changeset(params)
    |> Map.put(:action, :validate)

  {:noreply, assign(socket, changeset: changeset)}
end

def handle_event("save", %{"user" => params}, socket) do
  case Accounts.create_user(params) do
    {:ok, user} ->
      {:noreply,
       socket
       |> put_flash(:info, "User created!")
       |> push_navigate(to: ~p"/users/#{user}")}

    {:error, changeset} ->
      {:noreply, assign(socket, changeset: changeset)}
  end
end

# Real-time updates via PubSub
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "users")
  end
  {:ok, assign(socket, users: Accounts.list_users())}
end

def handle_info({:user_created, user}, socket) do
  {:noreply, update(socket, :users, &[user | &1])}
end

# Streams (efficient large lists)
def mount(_params, _session, socket) do
  {:ok, stream(socket, :users, Accounts.list_users())}
end

def handle_info({:user_created, user}, socket) do
  {:noreply, stream_insert(socket, :users, user)}
end
```

## Channels (WebSockets)
```elixir
# lib/my_app_web/channels/room_channel.ex
defmodule MyAppWeb.RoomChannel do
  use MyAppWeb, :channel

  def join("room:" <> room_id, _payload, socket) do
    {:ok, assign(socket, :room_id, room_id)}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast!(socket, "new_msg", %{body: body, user: socket.assigns.user})
    {:noreply, socket}
  end

  def handle_in("typing", _payload, socket) do
    broadcast_from!(socket, "typing", %{user: socket.assigns.user})
    {:reply, :ok, socket}
  end
end
```

## PubSub
```elixir
# Broadcast
Phoenix.PubSub.broadcast(MyApp.PubSub, "users", {:user_created, user})

# Subscribe (in LiveView mount or GenServer init)
Phoenix.PubSub.subscribe(MyApp.PubSub, "users")

# Handle in LiveView
def handle_info({:user_created, user}, socket) do
  {:noreply, update(socket, :users, fn users -> [user | users] end)}
end
```

## Testing
```elixir
# test/my_app_web/controllers/user_controller_test.exs
defmodule MyAppWeb.UserControllerTest do
  use MyAppWeb.ConnCase

  alias MyApp.Accounts

  @create_attrs %{name: "Tom", email: "tom@test.com"}
  @invalid_attrs %{name: nil, email: nil}

  setup do
    {:ok, user} = Accounts.create_user(@create_attrs)
    %{user: user}
  end

  describe "GET /users" do
    test "lists all users", %{conn: conn} do
      conn = get(conn, ~p"/users")
      assert html_response(conn, 200) =~ "Users"
    end
  end

  describe "POST /users" do
    test "creates user with valid data", %{conn: conn} do
      conn = post(conn, ~p"/users", user: @create_attrs)
      assert redirected_to(conn) =~ ~p"/users/"
    end

    test "renders errors with invalid data", %{conn: conn} do
      conn = post(conn, ~p"/users", user: @invalid_attrs)
      assert html_response(conn, 200) =~ "can&#39;t be blank"
    end
  end
end

# test/my_app/accounts_test.exs
defmodule MyApp.AccountsTest do
  use MyApp.DataCase

  alias MyApp.Accounts

  describe "users" do
    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "create_user/1 with valid data" do
      assert {:ok, %User{} = user} = Accounts.create_user(%{name: "Tom", email: "tom@t.com"})
      assert user.name == "Tom"
    end

    test "create_user/1 with invalid data" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(%{name: nil})
    end
  end
end
```

### LiveView Testing
```elixir
defmodule MyAppWeb.CounterLiveTest do
  use MyAppWeb.ConnCase
  import Phoenix.LiveViewTest

  test "increments count", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/counter")
    assert html =~ "Count: 0"

    assert view
           |> element("button", "+")
           |> render_click() =~ "Count: 1"
  end
end
```

## CLI Essentials
```bash
mix phx.new myapp                      # Create new Phoenix project
mix phx.new myapp --no-ecto            # Without database
mix phx.new myapp --no-html            # API only
mix phx.server                         # Start dev server (port 4000)
iex -S mix phx.server                  # Start with IEx shell

mix phx.gen.html Accounts User users name:string email:string
                                       # Generate context + schema + controller + views
mix phx.gen.json Accounts User users name:string email:string
                                       # Generate JSON API
mix phx.gen.live Accounts User users name:string email:string
                                       # Generate LiveView CRUD
mix phx.gen.context Accounts User users name:string
                                       # Generate context + schema only (no web layer)
mix phx.gen.schema User users name:string
                                       # Generate schema + migration only
mix phx.gen.auth Accounts User users
                                       # Generate full authentication system

mix phx.routes                         # Show all routes
mix ecto.gen.migration add_users       # Generate migration
mix ecto.migrate                       # Run migrations
mix ecto.reset                         # Drop + create + migrate

mix test                               # Run all tests
mix test test/my_app_web/              # Run directory
mix test test/my_app_web/controllers/user_controller_test.exs:15
                                       # Run specific line
```

## Phoenix is NOT Elixir

### This is Elixir (works anywhere)
```elixir
defmodule User do
  defstruct [:name, :email, active: true]

  def full_name(%User{name: name}), do: name
end

user = %User{name: "Tom"}
User.full_name(user)
```

### This is Phoenix/Ecto (needs Phoenix app)
```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema                      # Ecto (database)

  schema "users" do                    # Maps to DB table
    field :name, :string
    has_many :posts, MyApp.Blog.Post   # Ecto association
    timestamps()                       # Ecto timestamps
  end
end

# Phoenix controller
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller            # Phoenix macro

  def index(conn, _params) do          # conn is Phoenix
    render(conn, :index)               # Phoenix rendering
  end
end
```

### Common Confusion Points

| Feature | Elixir or Phoenix? | Notes |
|---------|-------------------|-------|
| `defmodule`, `def`, `defp` | **Elixir** | Core language |
| `defstruct` | **Elixir** | Core language |
| Pattern matching, pipes | **Elixir** | Core language |
| `Enum`, `Stream`, `Map` | **Elixir** | Standard library |
| `GenServer`, `Supervisor` | **Elixir/OTP** | Ships with Elixir |
| `use Ecto.Schema` | **Ecto** | Separate library (used by Phoenix) |
| `Repo.all`, `Repo.insert` | **Ecto** | Database operations |
| Changesets, validations | **Ecto** | Data validation |
| `conn`, `render`, `redirect` | **Phoenix** | Web layer |
| `~p"/path"` | **Phoenix** | Verified routes |
| LiveView, Channels | **Phoenix** | Real-time features |
| `mix phx.*` | **Phoenix** | Phoenix generators |
| `mix ecto.*` | **Ecto** | Database tasks |
| PubSub | **Phoenix** | Distributed messaging |
| HEEx templates | **Phoenix** | HTML templating |

## Key Differences from Rails
- **No inheritance**: Controllers are modules, not subclasses. Shared behavior comes from `use`, `import`, and plugs.
- **No instance variables in views**: Templates receive explicit assigns (`@name`, not `@user.name` from a controller ivar).
- **Contexts over fat models**: Business logic lives in context modules, not in schemas.
- **Changesets over callbacks**: Validation and data transformation happen in explicit changeset functions, not model callbacks.
- **Immutable conn**: The connection struct is passed through and transformed — not mutated in place.
- **Real-time built in**: LiveView and Channels are core, not bolted on.
- **No ActiveRecord**: Ecto is explicit — no implicit queries, no lazy loading, no `user.posts` triggering SQL behind the scenes.
- **Functional everything**: No `before_action` magic — plug pipelines are explicit and composable.

That's the essential Phoenix. The rest is mastering LiveView patterns, Ecto's query DSL, and building real-time features with PubSub and Channels.
