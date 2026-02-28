## Build and run a Docker container for OpenSSL and Ruby cross-platform testing
cd docker
docker build -t myopensslandruby .
cd ..
docker run -it -v .:/workdir --workdir /workdir myopensslandruby sh
