#!/usr/bin/env zsh

## expand the data.tar.gz of all the gems in a directory into subdirs of the same name

ls *.gem | xargs -I {} basename {} .gem | while read gem_name
do
  if [ ! -d $gem_name.gem ]; then mkdir $gem_name; fi
  pushd $gem_name
  tar xvf ../$gem_name.gem
  tar zxvf data.tar.gz
  popd
done
