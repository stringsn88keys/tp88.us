## set-executionpolicy unrestricted
git checkout main
#$ENV:CUSTOM_CHEF_POWERSHELL_BRANCH="tp/debug-ffi-yajl"
$ENV:CHEF_LICENSE="accept-no-persist"
bundle install
bundle exec ruby .\post-bundle-install.rb
bundle exec rspec -f progress --profile -- ./spec/unit
if ($? -ne 0) { throw "unit failed" }
bundle exec rspec -f progress --profile -- ./spec/functional
if ($? -ne 0) { throw "functional failed" }
bundle exec rspec -f progress --profile -- ./spec/integration
