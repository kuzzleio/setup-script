#!/bin/bash

here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
dir=/tmp/setupsh-$TRAVIS_COMMIT
badges_dir="$here/../setupsh-badges"

kssh () {
  ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no $MAC_USER@$MAC_HOST $@
}
kscp () {
  scp -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no "$1" $MAC_USER@$MAC_HOST:"$2"
}

echo Creating directory
kssh mkdir $dir

echo Copying files...
kscp $here/../setup.sh $dir
kscp $here/../test/ $dir

echo Running test
kssh $dir/test/run-macos.sh

if [ $? -eq 0 ]; then
  curl -sL https://img.shields.io/badge/setup.sh-osx-green.svg -o $badges_dir/osx.svg
else
  curl -sL https://img.shields.io/badge/setup.sh-osx-red.svg -o $badges_dir/osx.svg
fi

echo Cleaning up
kssh rm -rf $dir

