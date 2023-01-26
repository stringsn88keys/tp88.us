##
set-executionpolicy unrestricted
git checkout tp/ffi-378
$ENV:CUSTOM_CHEF_POWERSHELL_BRANCH="tp/debug-ffi-yajl"
$ENV:CHEF_LICENSE="accept-no-persist"
bundle install
bundle exec ruby .\post-bundle-install.rb
bundle exec rspec .\spec\integration\client\client_spec.rb
