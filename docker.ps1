cd docker
docker build -t myopensslandruby .
cd ..
docker run -it -v ${PWD}:/workdir --workdir /workdir myopensslandruby sh
