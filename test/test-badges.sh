#!/bin/bash

set -x

DEFAULT_DISTROS="fedora,ubuntu-artful,debian-jessie,osx"
IFS=', ' read -r -a DISTROS <<< "$DEFAULT_DISTROS"
BADGES_DIR=/tmp/setupsh-badges

[[ -d $BADGES_DIR ]] || mkdir $BADGES_DIR

for DISTRO in ${DISTROS[*]}
do
    FORMATTED_DISTRO=$(echo $DISTRO | sed 's/-/%20/g')
    BADGE_URL=https://img.shields.io/badge/setup.sh-$FORMATTED_DISTRO-red.svg
    echo "Requesting badge at $BADGE_URL ..."
    curl -L $BADGE_URL -o $BADGES_DIR/$DISTRO.svg
done