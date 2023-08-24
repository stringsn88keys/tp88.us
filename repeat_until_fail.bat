:loop
bundle exec rspec spec\function\resource\windows_certificate_spec.rb
if %errorlevel% == 0 goto loop
