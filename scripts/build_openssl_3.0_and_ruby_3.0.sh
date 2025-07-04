## Try to build openssl 3.0 with ruby 3.0
if [ `whoami` = "root" ]
then
  apt update && apt -y upgrade && apt install -y build-essential git checkinstall curl
else
  sudo apt update && sudo apt -y upgrade && sudo apt install -y build-essential git checkinstall curl
fi
openssl version
#exit
curl https://www.openssl.org/source/openssl-3.0.11.tar.gz --output openssl-3.0.11.tar.gz
tar zxvf openssl-3.0.11.tar.gz
cd openssl-3.0.11
./config
make
cd ..
curl https://cache.ruby-lang.org/pub/ruby/3.0/ruby-3.0.6.tar.gz --output ruby-3.0.6.tar.gz
tar zxvf ruby-3.0.6.tar.gz
cd ruby-3.0.6
./configure
make
make install
cd ..
curl https://rubygems.org/downloads/openssl-3.2.0.gem --output openssl-3.2.0.gem
gem install openssl-3.2.0.gem

ruby -e "require 'openssl'; %w[OpenSSL::OPENSSL_FIPS
OpenSSL::OPENSSL_LIBRARY_VERSION
OpenSSL::OPENSSL_VERSION].each { |e| puts e + ': ' + eval(e).to_s }"


