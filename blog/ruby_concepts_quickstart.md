# Ruby Quick Reference for Experienced Programmers

## Language Basics
- **Everything is an object**: Even `5` and `true` are objects with methods
- **Dynamic typing**: Variables don't have type declarations
- **Duck typing**: If it quacks like a duck... (respond_to? checks)
- **Blocks everywhere**: `{ }` or `do...end` - closures passed to methods
- **Symbols**: Immutable strings, `:symbol` - used for hash keys, method names

## Variables & Scope
```ruby
local_var = "local"           # Local variable
@instance_var = "instance"    # Instance variable (belongs to object)
@@class_var = "class"         # Class variable (shared across all instances)
$global_var = "global"        # Global variable (avoid these)
CONSTANT = "constant"         # Constant (can be changed but warns)
```

### Variable Scope Gotchas
```ruby
class User
  @@count = 0              # Class variable - shared across inheritance chain!
  @default_role = "user"   # Class instance variable - separate per class

  def initialize
    @@count += 1           # Increments shared counter
    @name = "unknown"      # Instance variable for this object
  end

  def self.count
    @@count                # Accessible from class method
  end

  def self.default_role
    @default_role          # Different @default_role per class
  end
end
```

**Key distinction**: `@@class_var` is shared across the inheritance chain (usually a mistake). `@class_instance_var` defined at class level is unique per class.

## Classes & Modules
```ruby
class User
  attr_reader :name           # Generates getter
  attr_writer :email          # Generates setter
  attr_accessor :age          # Generates both

  def initialize(name)
    @name = name              # Instance variable
  end

  def greet                   # Instance method
    "Hello, #{@name}"
  end

  def self.create_guest       # Class method (option 1)
    new("Guest")
  end

  class << self               # Class method (option 2 - multiple)
    def admin_count
      where(admin: true).count
    end

    def active_count
      where(active: true).count
    end
  end
end

# Usage
user = User.new("Tom")
user.greet                    # Instance method
User.create_guest             # Class method
```

## Modules & Mixins
```ruby
module Authenticatable
  # Instance methods added via 'include'
  def authenticate(password)
    password == @password
  end

  # Class methods via mixin pattern
  module ClassMethods
    def find_by_credentials(email, password)
      user = find_by(email: email)
      user&.authenticate(password) ? user : nil
    end
  end

  def self.included(base)
    base.extend(ClassMethods)  # Adds ClassMethods as class methods
  end
end

class User
  include Authenticatable      # Adds instance methods + triggers hook
end

# Now you have:
user.authenticate("secret")                        # Instance method
User.find_by_credentials("a@b.com", "secret")     # Class method
```

**Alternative modern pattern (ActiveSupport::Concern)**:
```ruby
module Authenticatable
  extend ActiveSupport::Concern

  included do
    # Code run when included
    validates :password, presence: true
  end

  def authenticate(password)
    # Instance method
  end

  class_methods do
    def find_by_credentials(email, password)
      # Class method
    end
  end
end
```

## Blocks, Procs, Lambdas
```ruby
# Block (not an object, passed to methods)
[1, 2, 3].each { |n| puts n }
[1, 2, 3].map do |n|
  n * 2
end

# Proc (object, loose arg checking)
double = Proc.new { |n| n * 2 }
double.call(5)  # => 10

# Lambda (object, strict arg checking, different return)
double = ->(n) { n * 2 }
double.call(5)  # => 10
double.(5)      # Alternative syntax

# Method accepting block
def with_timing
  start = Time.now
  yield                    # Calls the block
  puts "Took #{Time.now - start}s"
end

with_timing { sleep 1 }

# Block to proc conversion
def greet(&block)          # & converts block to Proc
  block.call("World")
end

greet { |name| "Hello #{name}" }
```

## Control Flow: next, break, return in Different Contexts

### In Loops
```ruby
# while loop
while true
  next      # Skip to next iteration
  break     # Exit loop entirely
  # return would exit the enclosing method
end

# for loop (rarely used - prefer enumerators)
for i in 0..5
  next if i == 2
  break if i == 4
end

# Idiomatic Ruby: Use enumerators instead of 'for'
(0..5).each do |i|
  # Preferred over 'for'
end

# Use each_with_index when you need the iteration number
items.each_with_index do |item, i|
  puts "#{i}: #{item}"
end

# Other useful enumerators
5.times { |i| puts i }           # 0 to 4
3.upto(7) { |i| puts i }         # 3 to 7
10.downto(5) { |i| puts i }      # 10 to 5
```

**Note**: The `for` loop exists but is rarely used in Ruby. Prefer `.each`, `.each_with_index`, `.times`, etc. They're more idiomatic and work better with blocks.

### In Blocks (each, map, etc.)
```ruby
[1, 2, 3].each do |n|
  next if n == 2        # Skip to next iteration (like 'continue')
  break if n == 3       # Exit the iteration entirely
  # return would exit the ENCLOSING METHOD, not just the block
end

# Practical example
def process_items
  [1, 2, 3].each do |n|
    return "early exit" if n == 2  # Returns from process_items!
  end
  "finished"
end
process_items  # => "early exit"
```

### In Procs vs Lambdas (CRITICAL DIFFERENCE)
```ruby
# Proc: 'return' exits the enclosing method
def proc_test
  p = Proc.new { return "from proc" }
  p.call
  "after proc"  # Never reached!
end
proc_test  # => "from proc"

# Lambda: 'return' exits only the lambda
def lambda_test
  l = ->(x) { return "from lambda" }
  l.call(5)
  "after lambda"  # This DOES execute
end
lambda_test  # => "after lambda"

# next/break work the same in both
p = Proc.new { next "skip" }   # Returns "skip" from the proc
p.call  # => "skip"
```

### Top-Level Context
```ruby
# In a script file:
return      # Returns from the file (exits script)
break       # SyntaxError: can't escape from eval with break
next        # SyntaxError: Invalid next

# Top-level in irb/pry:
return      # LocalJumpError
break       # LocalJumpError
```

### Summary Table
| Context | `next` | `break` | `return` |
|---------|--------|---------|----------|
| Loop (while/for) | Next iteration | Exit loop | Exit method |
| Block (each/map) | Next iteration | Exit iteration | **Exit enclosing method** |
| Proc | Return value from proc | Exit proc with value | **Exit enclosing method** |
| Lambda | Return value from lambda | Exit lambda with value | Exit lambda only |
| Method | N/A | N/A | Exit method with value |
| Top-level | Error | Error | Exit script/error |

**Key gotcha**: `return` in a block exits the method containing the block, not just the block!

## Common Idioms
```ruby
# Safe navigation
user&.name                 # Returns nil if user is nil

# Conditional assignment
x ||= 5                    # x = x || 5 (assigns if falsy)
x &&= 5                    # x = x && 5 (assigns if truthy)

# Ternary
status = active? ? "on" : "off"

# case/when (uses ===)
case value
when String then "text"
when 0..10 then "small number"
when Integer then "number"
else "unknown"
end

# Splat operators
def method(*args)          # Collects arguments into array
  args.each { |a| puts a }
end

arr = [1, 2, 3]
method(*arr)               # Expands array into arguments

def keyword_method(name:, age: 18)  # Keyword arguments
  "#{name} is #{age}"
end

# Double splat for hashes
def options(**opts)
  opts[:debug]
end
```

## String Interpolation & Symbols
```ruby
name = "Tom"
"Hello #{name}"            # Interpolation (double quotes only)
'Hello #{name}'            # Literal (single quotes)

%Q(Hello #{name})          # Alternative double quote
%q(Hello #{name})          # Alternative single quote

# Symbols (immutable, unique)
:symbol                    # Memory efficient for hash keys
{ name: "Tom" }            # Same as { :name => "Tom" }
```

## Enumerable Methods (Arrays/Hashes)
```ruby
[1, 2, 3].map { |n| n * 2 }              # => [2, 4, 6]
[1, 2, 3].select { |n| n > 1 }           # => [2, 3]
[1, 2, 3].reject { |n| n > 1 }           # => [1]
[1, 2, 3].reduce(0) { |sum, n| sum + n } # => 6
[1, 2, 3].each_with_index { |n, i| }
[1, 2, 3].any? { |n| n > 2 }             # => true
[1, 2, 3].all? { |n| n > 0 }             # => true

# Chaining
users.select(&:active?).map(&:email).sort
```

## Command Line Options
```bash
ruby script.rb              # Run script
ruby -e 'puts "hello"'      # Execute code
ruby -c script.rb           # Check syntax
ruby -w script.rb           # Warnings enabled
ruby -I./lib script.rb      # Add to load path
ruby -r debug script.rb     # Require library before running

# Useful globals
-d, --debug                 # Debug mode ($DEBUG = true)
-w, --warning               # Warnings
-v, --version               # Version info
-h, --help                  # Help
```

## Important Globals
```ruby
$0                          # Current script filename
$:  or  $LOAD_PATH          # Array of load paths
$?                          # Last process exit status
ARGV                        # Command line arguments array
ENV                         # Environment variables hash
__FILE__                    # Current file path
__LINE__                    # Current line number
__dir__                     # Current directory (Ruby 2.0+)

# Less common but useful
$stdin, $stdout, $stderr    # Standard streams
$DEBUG                      # Debug flag
$VERBOSE                    # Verbosity level
```

## Common Methods to Know
```ruby
# Object
.class                      # Object's class
.is_a?(Class)              # Type check
.respond_to?(:method)      # Duck typing check
.nil?                       # Nil check
.send(:method, args)        # Dynamic method call
.method(:name)              # Get method object

# String
.length / .size
.upcase / .downcase / .capitalize
.strip / .chomp             # Remove whitespace/newlines
.split / .join
.gsub(pattern, replacement) # Global substitute
.match(regex)
.to_i / .to_f / .to_sym

# Array
.length / .size / .count
.first / .last
.push / .pop / .shift / .unshift
.flatten / .compact         # Remove nesting / nils
.uniq / .sort
.include?(item)
& | -                       # Set operations

# Hash
.keys / .values
.fetch(key, default)
.merge(other_hash)
.dig(:key, :nested_key)     # Safe nested access
.transform_keys / .transform_values
```

## File I/O
```ruby
# Read
File.read("file.txt")                    # Entire file
File.readlines("file.txt")               # Array of lines

# Write
File.write("file.txt", "content")        # Overwrite
File.open("file.txt", "a") { |f| f.puts "append" }

# Block form (auto-closes)
File.open("file.txt") do |f|
  f.each_line { |line| puts line }
end

# Check existence
File.exist?("file.txt")
Dir.exist?("dir")
```

## Requiring Files
```ruby
require "json"              # Load from $LOAD_PATH (once)
require_relative "lib/helper"  # Relative to current file
load "script.rb"            # Always reload

# Autoload (lazy load)
autoload :MyClass, "my_class"
```

## Exception Handling
```ruby
begin
  # Code that might fail
  risky_operation
rescue SpecificError => e
  # Handle specific error
  puts e.message
  puts e.backtrace
rescue => e               # Catches StandardError
  # Handle any error
ensure
  # Always runs
end

# Inline rescue
value = risky_call rescue "default"

# Method-level rescue (implicit begin/end)
def save_user
  User.create!(name: "Tom")
  notify_admin
rescue ActiveRecord::RecordInvalid => e
  log_error(e)
  false
rescue => e
  log_error(e)
  raise  # Re-raise the exception
ensure
  cleanup_temp_files
end

# Raising
raise "Error message"
raise ArgumentError, "Bad argument"
raise ArgumentError.new("Bad argument")

# Retry
def fetch_data
  attempts = 0
  begin
    attempts += 1
    make_api_call
  rescue NetworkError => e
    retry if attempts < 3
    raise
  end
end
```

## Metaprogramming Basics
```ruby
# Define method dynamically
define_method(:greet) do |name|
  "Hello #{name}"
end

# Missing method handler
def method_missing(name, *args)
  if name.to_s.start_with?("find_by_")
    # Handle dynamically
  else
    super
  end
end

# Class eval
User.class_eval do
  def new_method
    "added later"
  end
end

# Instance eval
obj.instance_eval do
  @private_var = "accessible here"
end
```

## Testing (Minitest/RSpec basics)
```ruby
# Minitest
require "minitest/autorun"

class TestUser < Minitest::Test
  def test_creation
    user = User.new("Tom")
    assert_equal "Tom", user.name
  end
end

# RSpec
RSpec.describe User do
  it "creates with name" do
    user = User.new("Tom")
    expect(user.name).to eq("Tom")
  end
end
```

## Gems & Bundler
```bash
gem install rails           # Install gem globally
gem list                    # Show installed gems
gem uninstall rails         # Remove gem

# Bundler
bundle install              # Install from Gemfile
bundle update               # Update gems
bundle exec rake task       # Run with Bundler context
```
```ruby
# Gemfile
source "https://rubygems.org"

gem "rails", "~> 7.0"       # Pessimistic version
gem "pg"                    # Latest version
gem "debug", group: :development
```

## Ruby is NOT Rails

A common source of confusion: **Ruby is the language, Rails is a web framework written in Ruby.**

### This is Ruby (works anywhere)
```ruby
class User
  attr_accessor :name, :email

  def initialize(name, email)
    @name = name
    @email = email
  end

  def valid?
    !name.nil? && !email.nil?
  end
end

user = User.new("Tom", "tom@example.com")
puts user.name  # => "Tom"
```

### This is Rails (only works in Rails apps)
```ruby
class User < ApplicationRecord  # ApplicationRecord is Rails
  validates :name, presence: true     # Rails validation
  validates :email, presence: true

  has_many :posts                     # Rails association
  belongs_to :organization

  scope :active, -> { where(active: true) }  # Rails scope
end

# ActiveRecord query methods (Rails)
User.where(active: true).order(:name).limit(10)
User.find_by(email: "tom@example.com")
User.create(name: "Tom", email: "tom@example.com")
```

### Common Confusion Points

| Feature | Ruby or Rails? | Notes |
|---------|---------------|-------|
| `attr_accessor` | **Ruby** | Built into the language |
| `validates` | **Rails** | ActiveRecord/ActiveModel |
| `has_many`, `belongs_to` | **Rails** | ActiveRecord associations |
| `where`, `find`, `create` | **Rails** | ActiveRecord query interface |
| Classes, modules | **Ruby** | Core language features |
| `ApplicationRecord` | **Rails** | Base class for models |
| `params`, `session`, `cookies` | **Rails** | Controller/request objects |
| `render`, `redirect_to` | **Rails** | Controller methods |
| `link_to`, `form_with` | **Rails** | View helpers |
| Blocks, procs, lambdas | **Ruby** | Core language features |
| String methods (`.upcase`, `.strip`) | **Ruby** | Standard library |
| `.blank?`, `.present?` | **Rails** | ActiveSupport extensions |
| `.to_json` | **Ruby** (stdlib) | But Rails extends it heavily |
| `1.day.ago`, `2.weeks.from_now` | **Rails** | ActiveSupport time extensions |
| `.pluralize`, `.singularize` | **Rails** | ActiveSupport inflections |
| `Rails.logger` | **Rails** | Framework logger |
| `puts`, `print`, `p` | **Ruby** | Standard output methods |

### ActiveSupport Blurs the Line

Rails includes **ActiveSupport**, which adds many convenience methods to Ruby's core classes. These work in Rails but NOT in plain Ruby:
```ruby
# Plain Ruby - works everywhere
"hello".upcase              # => "HELLO"
[1, 2, 3].first             # => 1

# ActiveSupport (Rails only) - won't work in plain Ruby scripts
"hello".blank?              # Checks if empty/whitespace
[1, 2, 3].second            # => 2
1.day.ago                   # Time calculation
"user_name".camelize        # => "UserName"
{ a: 1 }.symbolize_keys     # Already symbols, but shows the method
```

To use ActiveSupport features outside Rails:
```ruby
require "active_support/all"
# Now you have Rails-style extensions in plain Ruby
```

### Testing: Where Things Get Mixed
```ruby
# Plain Ruby (Minitest) - works anywhere
require "minitest/autorun"

class TestUser < Minitest::Test
  def test_valid
    user = User.new("Tom", "tom@example.com")
    assert user.valid?
  end
end

# Rails testing - needs Rails environment
require "test_helper"  # Loads Rails

class UserTest < ActiveSupport::TestCase  # Rails base class
  test "should be valid" do
    user = users(:tom)  # Rails fixture
    assert user.valid?
  end
end
```

### Key Takeaway

If you're writing a **Ruby script** (automation, CLI tool, gem):
- Use only Ruby stdlib features
- Install specific gems you need
- No access to Rails helpers/methods

If you're in a **Rails application**:
- You have Ruby + Rails + ActiveSupport
- Models inherit from ApplicationRecord
- Controllers/views have tons of helper methods

**When learning**: Try features in plain `irb` vs `rails console` to see the difference!

## Key Differences from Other Languages
- No semicolons needed (but allowed)
- No `return` needed (last expression is returned)
- Everything is truthy except `false` and `nil`
- Parentheses optional for method calls: `puts "hi"` = `puts("hi")`
- Methods can end with `?` (predicate) or `!` (mutation/danger)
- Open classes: Can modify any class, even built-ins
- `return` in blocks exits the enclosing method (not the block!)
- Procs and lambdas handle `return` differently
- **Prefer enumerators over `for` loops**: Use `.each`, `.each_with_index`, `.times` instead
- **Ruby ≠ Rails**: Many "Ruby" features you see online are actually Rails

That's the essential Ruby. The rest is discovering the rich standard library and ecosystem.
