## run a focused test
set-executionpolicy unrestricted
git checkout tp/ffi-378-branch-install
$ENV:CUSTOM_CHEF_POWERSHELL_BRANCH="tp/debug-ffi-yajl"
$ENV:CHEF_LICENSE="accept-no-persist"
bundle install
bundle exec ruby .\post-bundle-install.rb
bundle exec rspec .\spec\integration\client\client_spec.rb
bundle exec rspec spec/functional/resource/windows_certificate_spec.rb
