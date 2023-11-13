FROM debian:bookworm
RUN apt-get update && apt install -y build-essential git checkinstall curl zlib1g-dev
#RUN curl https://www.openssl.org/source/openssl-3.0.11.tar.gz --output openssl-3.0.11.tar.gz
RUN curl https://www.openssl.org/source/openssl-3.0.1.tar.gz --output openssl-3.0.1.tar.gz
RUN tar zxvf openssl-3.0.1.tar.gz
WORKDIR openssl-3.0.1
RUN ./config
RUN make
RUN make install
WORKDIR ..
RUN curl https://cache.ruby-lang.org/pub/ruby/3.0/ruby-3.0.6.tar.gz --output ruby-3.0.6.tar.gz
RUN tar zxvf ruby-3.0.6.tar.gz
WORKDIR ruby-3.0.6
RUN ./configure
RUN make
RUN make install
WORKDIR ..
#ENV
RUN curl https://rubygems.org/downloads/openssl-3.2.0.gem --output openssl-3.2.0.gem

RUN gem install openssl-3.2.0.gem


