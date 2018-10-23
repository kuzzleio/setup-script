#!/bin/bash

FINAL_EXIT_VALUE=0
BADGES_DIR=./setupsh-badges
DEFAULT_DISTROS="fedora,ubuntu-artful,debian-stretch,osx"
REPORT_FILE=.setupsh-test.report

[[ -f $REPORT_FILE ]] && rm $REPORT_FILE
[[ -d $BADGES_DIR ]] || mkdir $BADGES_DIR

if [ "$SETUPSH_SHOW_DEBUG" != "" ]; then
  ARGS="--show-debug"
fi

if [ -z $SETUPSH_TEST_DISTROS ]; then
  IFS=', ' read -r -a DISTROS <<< "$DEFAULT_DISTROS"
else
  IFS=', ' read -r -a DISTROS <<< "$SETUPSH_TEST_DISTROS"
fi

for DISTRO in ${DISTROS[*]}
do
  if [ "$DISTRO" = "osx" ]; then
    if [ "$MAC_USER" == "" ] || [ "$MAC_HOST" == "" ]; then
      echo
      echo "Environment variables MAC_USER and MAC_HOST are needed by this script"
      echo "but they do not seem to be set. Aborting."
      echo
      exit -1
    fi
    
    echo
    echo "Setting up test environment on remote Mac..."
    echo

    MAC_FOLDER=/tmp/kuzzle-build-$TRAVIS_COMMIT
    echo -n "Creating directory..."
    ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no $MAC_USER@$MAC_HOST "mkdir $MAC_FOLDER"
    echo " Done."
    echo -n "Copying files..."
    scp -i ~/.ssh/id_rsa -r -o StrictHostKeyChecking=no ./setup.sh $MAC_USER@$MAC_HOST:$MAC_FOLDER
    scp -i ~/.ssh/id_rsa -r -o StrictHostKeyChecking=no ./test/ $MAC_USER@$MAC_HOST:$MAC_FOLDER
    echo " Done."
    ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no $MAC_USER@$MAC_HOST "$MAC_FOLDER/test/run-macos.sh"
    EXIT_VALUE=$?
    echo
    echo -n "Cleaning up..."
    ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no $MAC_USER@$MAC_HOST "rm -rf $MAC_FOLDER"
    echo " Done."
  else
    ${BASH_SOURCE%/*}/test-setup.sh $DISTRO $ARGS
    EXIT_VALUE=$?
  fi
  FORMATTED_DISTRO=$(echo $DISTRO | sed 's/-/%20/g')
  if [ $EXIT_VALUE -ne 0 ]; then
      FINAL_EXIT_VALUE=$EXIT_VALUE
      echo
      echo "========================================"
      echo "[✖] Tests on $DISTRO are RED."
      echo "========================================"
      echo
      echo "[$DISTRO] Failed." >> $REPORT_FILE
      curl -L https://img.shields.io/badge/setup.sh-$FORMATTED_DISTRO-red.svg -o $BADGES_DIR/$DISTRO.svg
  else
      echo
      echo "========================================="
      echo "[✔] Tests on $DISTRO are GREEN."
      echo "========================================="
      echo
      echo "[$DISTRO] Succeeded." >> $REPORT_FILE
      curl -L https://img.shields.io/badge/setup.sh-$FORMATTED_DISTRO-green.svg -o $BADGES_DIR/$DISTRO.svg
  fi
done

echo
echo "============ Test Results ==============="
cat $REPORT_FILE
echo "========================================="

exit $FINAL_EXIT_VALUE
