## Try to build openssl 3.0 with ruby 3.0
sudo apt update && sudo apt -y upgrade && sudo apt install -y build-essential git checkinstall
curl https://www.openssl.org/source/openssl-3.0.1.tar.gz --output openssl-3.0.1.tar.gz
tar zxvf openssl-3.0.1.tar.gz
pushd openssl-3.0.1
./config
make
popd
curl https://cache.ruby-lang.org/pub/ruby/3.0/ruby-3.0.6.tar.gz --output ruby-3.0.6.tar.gz
tar zxvf ruby-3.0.6.tar.gz
pushd ruby-3.0.6
./configure
make
popd
ruby -e "require 'openssl'; %w[OpenSSL::OPENSSL_FIPS
OpenSSL::OPENSSL_LIBRARY_VERSION
OpenSSL::OPENSSL_VERSION].each { |e| puts e + ': ' + eval(e).to_s }"
    

