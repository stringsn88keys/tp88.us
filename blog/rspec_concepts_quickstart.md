# RSpec Quick Reference for Experienced Programmers

## For more see:
* [RSpec Documentation](https://rspec.info/documentation/)
* [Better Specs](https://www.betterspecs.org/)

## Core Structure
- **describe/context**: Group examples by class, method, or scenario. `describe` for what you're testing, `context` for conditions.
- **it/specify**: Individual test cases (examples). The string describes expected behavior.
- **expect**: Assertion syntax. `expect(x).to eq(y)` replaces older `should` syntax.
- **before/after/around**: Hooks for setup/teardown at different scopes.

## Basic Anatomy
```ruby
RSpec.describe User do
  describe "#full_name" do              # Instance method
    context "when first and last name are present" do
      it "returns the full name" do
        user = User.new(first: "Tom", last: "Powell")
        expect(user.full_name).to eq("Tom Powell")
      end
    end

    context "when last name is missing" do
      it "returns just the first name" do
        user = User.new(first: "Tom", last: nil)
        expect(user.full_name).to eq("Tom")
      end
    end
  end

  describe ".create_guest" do           # Class method
    it "creates a user with guest role" do
      user = User.create_guest
      expect(user.role).to eq("guest")
    end
  end
end
```

### Naming Conventions
| Prefix | Meaning | Example |
|--------|---------|---------|
| `#method` | Instance method | `describe "#save"` |
| `.method` | Class method | `describe ".find"` |
| `context "when..."` | Conditional state | `context "when logged in"` |
| `context "with..."` | Input variation | `context "with invalid email"` |
| `context "without..."` | Absence | `context "without a name"` |

## Matchers

### Equality
```ruby
expect(x).to eq(y)                    # Value equality (==)
expect(x).to eql(y)                   # Type + value equality (eql?)
expect(x).to equal(y)                 # Object identity (equal? / same object)
expect(x).to be(y)                    # Same as equal (object identity)
```

### Comparison
```ruby
expect(x).to be > 5
expect(x).to be >= 5
expect(x).to be < 10
expect(x).to be_between(1, 10).inclusive
expect(x).to be_within(0.01).of(3.14)
```

### Truthiness
```ruby
expect(x).to be true                  # Exactly true
expect(x).to be false                 # Exactly false
expect(x).to be_truthy                # Anything except false/nil
expect(x).to be_falsey                # false or nil
expect(x).to be_nil                   # Exactly nil
```

### Collections
```ruby
expect(arr).to include(1, 3)          # Contains elements
expect(arr).to contain_exactly(3, 1, 2)  # Exact elements, any order
expect(arr).to match_array([3, 1, 2]) # Same as contain_exactly
expect(arr).to start_with(1)
expect(arr).to end_with(3)
expect(arr).to all(be > 0)            # Every element matches
expect(arr).to be_empty
expect(hash).to include(name: "Tom")  # Hash key/value
expect(arr).to have_attributes(name: "Tom")  # Object attributes
```

### Strings / Regex
```ruby
expect(str).to include("hello")
expect(str).to start_with("he")
expect(str).to end_with("lo")
expect(str).to match(/^hello/)
```

### Types
```ruby
expect(obj).to be_a(User)             # is_a? check
expect(obj).to be_an(Array)
expect(obj).to be_an_instance_of(User) # Exact class (no subclasses)
expect(obj).to respond_to(:name)
expect(obj).to respond_to(:save).with(2).arguments
```

### Changes
```ruby
expect { user.save }.to change(user, :updated_at)
expect { user.activate }.to change(user, :active).from(false).to(true)
expect { list.push(1) }.to change(list, :length).by(1)
expect { User.create }.to change(User, :count).by(1)

# Block form
expect { x += 1 }.to change { x }.from(0).to(1)
```

### Errors / Exceptions
```ruby
expect { raise "boom" }.to raise_error
expect { raise "boom" }.to raise_error(RuntimeError)
expect { raise "boom" }.to raise_error("boom")
expect { raise "boom" }.to raise_error(/boom/)
expect { raise ArgumentError, "bad" }.to raise_error(ArgumentError, "bad")

# No error
expect { safe_call }.not_to raise_error
```

### Output
```ruby
expect { puts "hello" }.to output("hello\n").to_stdout
expect { warn "oops" }.to output(/oops/).to_stderr
```

### Predicate Matchers (Dynamic)
```ruby
# RSpec auto-generates matchers from predicate methods (methods ending in ?)
expect(user).to be_active              # Calls user.active?
expect(list).to be_empty              # Calls list.empty?
expect(user).to be_valid              # Calls user.valid?
expect(value).to be_zero              # Calls value.zero?

# "have_" prefix for has_? methods
expect(user).to have_posts            # Calls user.has_posts?
expect(hash).to have_key(:name)       # Calls hash.has_key?(:name)
```

### Negation
```ruby
expect(x).not_to eq(5)                # Any matcher can be negated
expect(x).to_not eq(5)                # Alternative (same thing)
```

## let and let!
```ruby
RSpec.describe User do
  let(:user) { User.new(name: "Tom") }        # Lazy - created on first use
  let!(:admin) { User.create(role: "admin") }  # Eager - created before each example

  it "has a name" do
    expect(user.name).to eq("Tom")     # user is created here
  end
end
```

### let vs instance variables
```ruby
# Prefer let over instance variables in before blocks
# Bad
before { @user = User.new(name: "Tom") }

# Good
let(:user) { User.new(name: "Tom") }
```

**Why**: `let` is lazy (only created when referenced), memoized per example, and scoped properly. Instance variables return `nil` silently if you typo the name.

## subject
```ruby
RSpec.describe User do
  # Implicit subject - calls User.new
  it { is_expected.to respond_to(:name) }

  # Named subject
  subject(:user) { User.new(name: "Tom") }

  it { is_expected.to be_valid }

  # Explicit use
  it "has a name" do
    expect(subject.name).to eq("Tom")
    # or
    expect(user.name).to eq("Tom")
  end
end
```

## Hooks (before / after / around)
```ruby
RSpec.describe User do
  before(:each) do    # Runs before each example (default scope)
    @count = 0
  end

  before(:all) do     # Runs once before all examples in this group
    DatabaseCleaner.start
  end

  after(:each) do     # Runs after each example
    cleanup
  end

  after(:all) do      # Runs once after all examples
    DatabaseCleaner.clean
  end

  around(:each) do |example|
    Timeout.timeout(5) { example.run }
  end
end
```

| Scope | Alias | When |
|-------|-------|------|
| `:each` | `:example` | Before/after every single `it` block |
| `:all` | `:context` | Once per `describe`/`context` group |
| `:suite` | - | Once for the entire test run (in `spec_helper.rb`) |

**Warning**: `before(:all)` state isn't rolled back between examples. Don't use it for database records in transactional tests.

## Shared Examples & Shared Contexts
```ruby
# Shared examples - reusable test groups
RSpec.shared_examples "a timestamped model" do
  it "has created_at" do
    expect(subject).to respond_to(:created_at)
  end

  it "has updated_at" do
    expect(subject).to respond_to(:updated_at)
  end
end

RSpec.describe User do
  subject { User.new }
  it_behaves_like "a timestamped model"
end

RSpec.describe Post do
  subject { Post.new }
  it_behaves_like "a timestamped model"
end

# Shared context - reusable setup
RSpec.shared_context "with authenticated user" do
  let(:user) { create(:user) }
  before { sign_in(user) }
end

RSpec.describe "Dashboard" do
  include_context "with authenticated user"

  it "shows welcome message" do
    expect(page).to have_content("Welcome")
  end
end
```

## Mocks and Stubs (Test Doubles)

### Stubs (Method Return Values)
```ruby
user = double("User")                       # Generic test double
allow(user).to receive(:name).and_return("Tom")
user.name  # => "Tom"

# Stub on real object
allow(User).to receive(:find).and_return(user)

# Multiple return values
allow(die).to receive(:roll).and_return(1, 2, 3)
die.roll  # => 1
die.roll  # => 2
die.roll  # => 3

# Stub with block
allow(user).to receive(:age) { 25 + 5 }

# Stub and call original
allow(user).to receive(:name).and_call_original

# Raise error
allow(api).to receive(:fetch).and_raise(Timeout::Error)
```

### Mocks (Message Expectations)
```ruby
# Expect a method to be called
expect(mailer).to receive(:send_welcome).with(user)
mailer.send_welcome(user)                   # Must happen or test fails

# Called specific number of times
expect(logger).to receive(:info).exactly(3).times
expect(logger).to receive(:info).at_least(:once)
expect(logger).to receive(:info).at_most(:twice)

# Not called
expect(mailer).not_to receive(:send_spam)

# With argument matchers
expect(api).to receive(:post).with("/users", hash_including(name: "Tom"))
expect(api).to receive(:get).with(anything)
expect(api).to receive(:get).with(instance_of(String))
expect(api).to receive(:post).with(a_string_matching(/users/))
```

### Verified Doubles
```ruby
# Verified doubles check that methods actually exist on the real class
user = instance_double("User", name: "Tom")  # Only allows methods User has
user = class_double("User")                  # For class methods
user = object_double(User.new)               # Based on specific instance

# Will raise if User doesn't have a #name method
allow(user).to receive(:name).and_return("Tom")

# Will raise - :nonexistent isn't a real method
allow(user).to receive(:nonexistent)  # Error!
```

### Spies (Assert After the Fact)
```ruby
mailer = spy("Mailer")                       # Records all calls
mailer.send_welcome(user)                    # Just records it

# Assert after
expect(mailer).to have_received(:send_welcome).with(user)

# On real objects
allow(UserMailer).to receive(:welcome)
UserMailer.welcome(user)
expect(UserMailer).to have_received(:welcome).with(user)
```

### Partial Doubles (Stubbing Real Objects)
```ruby
user = User.new(name: "Tom")
allow(user).to receive(:admin?).and_return(true)

# Now user.admin? returns true but everything else is real
expect(user.name).to eq("Tom")
expect(user.admin?).to be true
```

## Factory Bot (Common with RSpec in Rails)
```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    name { "Tom" }
    email { "tom@example.com" }
    sequence(:username) { |n| "user_#{n}" }

    trait :admin do
      role { "admin" }
    end

    trait :with_posts do
      after(:create) do |user|
        create_list(:post, 3, user: user)
      end
    end
  end
end

# Usage in specs
let(:user) { create(:user) }                 # Persisted to DB
let(:user) { build(:user) }                  # In memory only
let(:admin) { create(:user, :admin) }        # With trait
let(:user) { create(:user, :with_posts) }    # With callback trait
let(:user) { build_stubbed(:user) }          # Fake persistence (fastest)
```

## Rails-Specific RSpec (rspec-rails)

### Model Specs
```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:email) }
    it { is_expected.to validate_length_of(:name).is_at_most(50) }
  end

  describe "associations" do
    it { is_expected.to have_many(:posts).dependent(:destroy) }
    it { is_expected.to belong_to(:organization) }
    it { is_expected.to have_one(:profile) }
  end

  describe "#deactivate!" do
    it "sets active to false" do
      user = create(:user, active: true)
      user.deactivate!
      expect(user.reload.active).to be false
    end
  end
end
```

### Request Specs (Preferred Over Controller Specs)
```ruby
# spec/requests/users_spec.rb
RSpec.describe "Users", type: :request do
  describe "GET /users" do
    it "returns a successful response" do
      get users_path
      expect(response).to have_http_status(:ok)
    end

    it "returns JSON list of users" do
      create_list(:user, 3)
      get users_path, as: :json
      expect(JSON.parse(response.body).length).to eq(3)
    end
  end

  describe "POST /users" do
    let(:valid_params) { { user: { name: "Tom", email: "tom@example.com" } } }

    it "creates a new user" do
      expect {
        post users_path, params: valid_params
      }.to change(User, :count).by(1)
    end

    it "returns unprocessable entity with invalid params" do
      post users_path, params: { user: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
```

### System Specs (Integration / Feature Tests)
```ruby
# spec/system/user_registration_spec.rb
RSpec.describe "User Registration", type: :system do
  before { driven_by(:rack_test) }  # or :selenium_chrome_headless

  it "allows a user to register" do
    visit new_user_registration_path
    fill_in "Name", with: "Tom"
    fill_in "Email", with: "tom@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign Up"
    expect(page).to have_content("Welcome, Tom")
  end
end
```

### Mailer Specs
```ruby
# spec/mailers/user_mailer_spec.rb
RSpec.describe UserMailer, type: :mailer do
  describe "#welcome" do
    let(:user) { create(:user) }
    let(:mail) { described_class.welcome(user) }

    it "renders the subject" do
      expect(mail.subject).to eq("Welcome!")
    end

    it "sends to the user's email" do
      expect(mail.to).to eq([user.email])
    end

    it "includes the user's name" do
      expect(mail.body.encoded).to include(user.name)
    end
  end
end
```

### Job Specs
```ruby
# spec/jobs/cleanup_job_spec.rb
RSpec.describe CleanupJob, type: :job do
  it "enqueues the job" do
    expect {
      described_class.perform_later
    }.to have_enqueued_job(described_class)
  end

  it "performs cleanup" do
    create(:user, expired: true)
    described_class.perform_now
    expect(User.where(expired: true)).to be_empty
  end
end
```

## Shoulda Matchers (Common Addon)
```ruby
# One-liner validations and associations
it { is_expected.to validate_presence_of(:name) }
it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
it { is_expected.to validate_numericality_of(:age).is_greater_than(0) }
it { is_expected.to validate_inclusion_of(:role).in_array(%w[admin user]) }
it { is_expected.to have_many(:posts) }
it { is_expected.to belong_to(:organization).optional }
it { is_expected.to have_db_column(:name).of_type(:string) }
it { is_expected.to have_db_index(:email).unique }
it { is_expected.to delegate_method(:name).to(:organization).with_prefix }
```

## CLI Essentials
```bash
bundle exec rspec                        # Run all specs
bundle exec rspec spec/models/           # Run directory
bundle exec rspec spec/models/user_spec.rb        # Run file
bundle exec rspec spec/models/user_spec.rb:15     # Run specific line
bundle exec rspec --tag focus            # Run focused tests
bundle exec rspec --format documentation # Verbose output
bundle exec rspec --fail-fast            # Stop on first failure
bundle exec rspec --only-failures        # Re-run failures (needs config)
bundle exec rspec --seed 12345           # Reproduce random order
bundle exec rspec --profile              # Show slowest examples
```

## Filtering & Focus
```ruby
# Focus on specific tests
fit "this test only" do ... end          # focus + it
fdescribe "this group only" do ... end   # focus + describe
fcontext "this context only" do ... end  # focus + context

# Skip tests
xit "skip this" do ... end               # Pending
xdescribe "skip group" do ... end
pending "not implemented yet"            # Inside an example

# Tag-based filtering
it "slow test", :slow do ... end
# Run with: rspec --tag slow
# Exclude:  rspec --tag ~slow
```

## Configuration (spec_helper.rb / rails_helper.rb)
```ruby
# spec/spec_helper.rb
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true  # Catch stubbing nonexistent methods
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus  # Enable fit/fdescribe
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!         # No should syntax
  config.order = :random                  # Randomize test order
end

# spec/rails_helper.rb (Rails only)
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rspec/rails"

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join("spec/fixtures")]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # FactoryBot
  config.include FactoryBot::Syntax::Methods

  # Shoulda Matchers
  Shoulda::Matchers.configure do |c|
    c.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end
end
```

## Directory Layout
```
spec/
  spec_helper.rb          # Core RSpec config
  rails_helper.rb         # Rails-specific config (loads Rails env)
  models/                 # Model specs
  requests/               # Request/API specs (preferred over controllers/)
  system/                 # Browser integration tests
  jobs/                   # Background job specs
  mailers/                # Mailer specs
  services/               # Service object specs
  support/                # Shared helpers, custom matchers, configs
    factory_bot.rb
    shoulda_matchers.rb
  factories/              # FactoryBot factory definitions
    users.rb
    posts.rb
  fixtures/               # Test data files
```

## Custom Matchers
```ruby
# spec/support/matchers/be_valid_email.rb
RSpec::Matchers.define :be_valid_email do
  match do |actual|
    actual.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
  end

  failure_message do |actual|
    "expected '#{actual}' to be a valid email address"
  end
end

# Usage
expect(user.email).to be_valid_email
```

## Aggregate Failures
```ruby
# Group multiple expectations - reports all failures, not just the first
it "has correct attributes" do
  aggregate_failures "user attributes" do
    expect(user.name).to eq("Tom")
    expect(user.email).to eq("tom@example.com")
    expect(user.role).to eq("admin")
  end
end

# Or via metadata
it "has correct attributes", :aggregate_failures do
  expect(user.name).to eq("Tom")
  expect(user.email).to eq("tom@example.com")
end
```

## Common Patterns

### Testing Scopes
```ruby
describe ".active" do
  it "returns only active users" do
    active = create(:user, active: true)
    inactive = create(:user, active: false)
    expect(User.active).to contain_exactly(active)
  end
end
```

### Testing Time-Dependent Code
```ruby
it "expires after 24 hours" do
  token = create(:token)
  travel_to 25.hours.from_now do   # Rails time helper
    expect(token).to be_expired
  end
end
```

### Testing Callbacks
```ruby
it "normalizes email before save" do
  user = create(:user, email: "TOM@Example.COM")
  expect(user.email).to eq("tom@example.com")
end
```

## Key Differences from Other Test Frameworks
- **BDD style**: `describe`/`context`/`it` reads like documentation
- **Lazy evaluation**: `let` only runs when referenced
- **Rich matchers**: Composable, readable, custom-friendly
- **No `assert`**: Uses `expect(...).to` syntax exclusively
- **Implicit subject**: `described_class.new` is automatic
- **Verified doubles**: Catch stubbing errors at test time
- **Metadata tags**: Filter, configure, and customize per-example behavior
- **`before(:all)` pitfall**: Shared state won't be rolled back transactionally
- **Prefer `let` over `before` + instance vars**: Lazy, memoized, typo-safe

That's the essential RSpec. The rest is mastering matcher composition and keeping tests fast and focused.
