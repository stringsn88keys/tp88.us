"aixopenssl3.sh" 23 lines, 693 characters
## Try to build openssl 3.0 with ruby 3.0
curl -k https://www.openssl.org/source/openssl-3.0.11.tar.gz --output openssl-3.0.11.tar.gz
gzip -d openssl-3.0.11.tar.gz
tar xvf openssl-3.0.11.tar

cd openssl-3.0.11
perl ./Configure aix64-cc --prefix=/opt/chef/embedded no-unit-test no-comp no-idea no-mdc2 no-rc5 no-ssl2 no-ssl3 no-zlib shared -DOPENSSL_TRUSTED_FIRST_DEFAULT -q64 -I/opt/chef/embedded/include -D_LARGE_FILES -O
make
cd ..
curl -k https://cache.ruby-lang.org/pub/ruby/3.0/ruby-3.0.6.tar.gz --output ruby-3.0.6.tar.gz
gzip -d ruby-3.0.6.tar.gz
tar xvf ruby-3.0.6.tar
cd ruby-3.0.6
./configure
make
make install
cd ..
curl -k https://rubygems.org/downloads/openssl-3.2.0.gem --output openssl-3.2.0.gem
gem install openssl-3.2.0.gem

ruby -e "require 'openssl'; %w[OpenSSL::OPENSSL_FIPS
OpenSSL::OPENSSL_LIBRARY_VERSION
OpenSSL::OPENSSL_VERSION].each { |e| puts e + ': ' + eval(e).to_s }"
