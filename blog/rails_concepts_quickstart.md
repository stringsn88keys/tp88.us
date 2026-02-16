# Rails Quick Reference for Experienced Programmers

## For more see:
* [Getting Started with Rails](https://guides.rubyonrails.org/getting_started.html)

## MVC Architecture
- **Models** (ActiveRecord): Database tables = Ruby classes. Associations (`has_many`, `belongs_to`), validations, and queries all in the model. Migrations version-control your schema.
- **Controllers**: HTTP routing → controller actions. Convention: `UsersController#show` maps to `/users/:id`. Actions render views or return JSON.
- **Views**: ERB templates (Ruby embedded in HTML). Layouts wrap views. Partials for reuse.

## Convention Over Configuration
- File paths = class names: `app/models/user.rb` → `User` class
- Database tables are pluralized model names: `User` → `users` table
- Follow conventions → zero config. Fight them → pain.

## Key Components
- **Routes** (`config/routes.rb`): RESTful by default. `resources :users` gives you 7 CRUD routes.
- **ActiveRecord**: ORM with chainable queries. `User.where(active: true).order(:name)` → SQL
- **Migrations**: Schema changes as Ruby code. Run with `rails db:migrate`
- **Asset Pipeline** (or Propshaft/Importmaps now): JS/CSS compilation/bundling
- **Gems**: Bundler manages dependencies via `Gemfile`

## Routes Conventions
```ruby
# config/routes.rb
resources :posts  # Creates 7 RESTful routes:
```

| HTTP Verb | Path | Controller#Action | Purpose |
|-----------|------|-------------------|---------|
| GET | /posts | posts#index | List all |
| GET | /posts/new | posts#new | New form |
| POST | /posts | posts#create | Create |
| GET | /posts/:id | posts#show | Show one |
| GET | /posts/:id/edit | posts#edit | Edit form |
| PATCH/PUT | /posts/:id | posts#update | Update |
| DELETE | /posts/:id | posts#destroy | Delete |
```ruby
# Nested resources
resources :posts do
  resources :comments  # /posts/:post_id/comments
end

# Custom routes
get 'about', to: 'pages#about'
root 'posts#index'  # Homepage

# Namespace
namespace :admin do
  resources :users  # /admin/users → Admin::UsersController
end
```

## CLI Essentials
```bash
rails new myapp          # Scaffold new app
rails generate model User name:string email:string
rails generate controller Users
rails db:migrate         # Run pending migrations
rails console            # IRB with app loaded
rails server             # Start dev server (port 3000)
rails routes             # Show all routes
```

## Migration Commands
```bash
rails db:migrate                    # Run all pending migrations
rails db:rollback                   # Undo last migration
rails db:rollback STEP=3            # Undo last 3 migrations
rails db:migrate:down VERSION=20240101120000  # Undo a specific migration
rails db:migrate:up VERSION=20240101120000    # Run a specific migration
rails db:migrate VERSION=20240101120000       # Migrate to a specific version (up or down)
rails db:migrate:status             # Show status of all migrations (up/down)
rails db:migrate:redo               # Rollback then re-run last migration
rails db:migrate:redo STEP=3        # Rollback then re-run last 3 migrations
rails db:reset                      # Drop, recreate, and re-migrate the database
rails db:seed                       # Run db/seeds.rb
```

## Directory Layout
- `app/` - Your code (models, views, controllers)
- `config/` - Routes, database.yml, application config
- `db/` - Migrations, schema.rb, seeds.rb
- `lib/` - Custom modules
- `public/` - Static files
- `test/` or `spec/` - Tests

## ActiveRecord Patterns
```ruby
User.create(name: "Tom")
User.find(1)
User.where(admin: true).first
user.posts  # Association from has_many :posts
```

## Associations
```ruby
class User < ApplicationRecord
  has_many :posts                    # user.posts → looks for user_id in posts table
  has_many :comments, through: :posts # user.comments via join
  has_one :profile                   # user.profile → looks for user_id in profiles table
  has_and_belongs_to_many :roles     # join table: roles_users (alphabetical)
end

class Post < ApplicationRecord
  belongs_to :user                   # post.user → requires user_id column on posts table
  belongs_to :author, class_name: "User", foreign_key: "author_id"  # custom name
  has_many :comments, dependent: :destroy  # delete comments when post is deleted
end
```

### Column Naming Conventions
- `belongs_to :user` expects a `user_id` column (integer/bigint) on the current model's table
- `belongs_to :author, class_name: "User"` expects an `author_id` column
- General rule: `belongs_to :something` → needs `something_id` column
- `has_many`/`has_one` don't add columns to the current table — the foreign key lives on the **other** table

### Common Association Options
| Option | Example | Purpose |
|--------|---------|---------|
| `dependent` | `has_many :posts, dependent: :destroy` | What happens to children when parent is deleted (`:destroy`, `:nullify`, `:restrict_with_error`) |
| `foreign_key` | `belongs_to :author, foreign_key: "author_id"` | Specify non-conventional FK column |
| `class_name` | `belongs_to :author, class_name: "User"` | When association name differs from class |
| `through` | `has_many :tags, through: :taggings` | Join through another association |
| `inverse_of` | `has_many :posts, inverse_of: :author` | Helps Rails recognize bidirectional associations |
| `optional` | `belongs_to :team, optional: true` | Allow nil (belongs_to is required by default in Rails 5+) |
| `counter_cache` | `belongs_to :user, counter_cache: true` | Cache count in parent (needs `posts_count` column on users) |

### Migration for Associations
```ruby
# Generate a migration that adds a foreign key
rails generate migration AddUserToPosts user:references

# Produces:
class AddUserToPosts < ActiveRecord::Migration[7.0]
  def change
    add_reference :posts, :user, null: false, foreign_key: true
    # Creates user_id column + index + DB-level foreign key constraint
  end
end
```

## Modern Rails (~7.x)
- Hotwire (Turbo + Stimulus) instead of heavy JS frameworks
- Importmaps or esbuild for JS
- Tailwind integration common
