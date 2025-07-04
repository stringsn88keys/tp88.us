cd docker
docker build -t myopensslandruby .
cd ..
docker run -it -v .:/workdir --workdir /workdir myopensslandruby sh
