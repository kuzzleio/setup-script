#!/bin/bash

set -e
set -o pipefail

here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
dist=$1
container=setupsh-$dist
output=/dev/null
badges_dir=$here/../setupsh-badges
badge_label=$(echo "$dist" | sed 's/-/%20/')

_error () {
  # mark test as red
  curl -L https://img.shields.io/badge/setup.sh-${badge_label}-red.svg -o $badges_dir/$dist.svg

  remove_container
}

trap _error INT ERR

remove_container() {
    echo "Removing container..."
    docker ps | grep $container && docker kill $container > /dev/null
    echo "Done."
}

trap remove_container TERM EXIT

if [ "$2" == "--show-debug" ]; then
  echo "DEBUG MODE ON"
  output=/dev/tty
fi

# build image
echo " Build & launch container"
docker build -q -t $container $here/docker/$dist
docker run -d \
  --privileged \
  --rm \
  --name $container \
  --add-host=analytics.kuzzle.io:127.0.0.1 \
  -v $PWD:/opt \
  $container

echo



# Test - Check cUrl
#########################################

# We only test cUrl if the tested distribution comes
# without it (like, Fedora comes with cUrl)
if [ -z $(docker exec -t $container sh -c "command -v curl") ]; then
    docker exec -t $container \
      ./setupsh.should "fail if curl is not installed" "This script needs curl" 43
fi


# Test - Check internet connection
#########################################

# Setup (install curl and shut eth0 down)
echo " Installing curl..."
docker exec -t $container /opt/test/fixtures-setupsh/install-curl.sh > $output
echo " Shutting down eth0..."
docker exec -t $container ip link set down dev eth0 > $output

# Check internet
docker exec -t $container \
  ./setupsh.should "fail if offline" "No internet" 42

# Teardown (switch eth0 back on)
echo " Bringing up eth0..."
docker exec -t $container ip link set up dev eth0 > $output
docker exec -t $container ip r a default via 172.17.0.1 dev eth0 > $output


# Test - Check docker
#########################################
docker exec -t $container \
  ./setupsh.should "fail if docker is not installed" "You need docker to run Kuzzle" 44

# Test - Check docker-compose
#########################################

# Setup (install docker)
echo " Installing docker..."
docker exec -t $container /opt/test/fixtures-setupsh/install-docker.sh > $output

# Check docker-compose
docker exec -t $container ./setupsh.should \
  "fail if docker-compose is not installed" "You need docker-compose to be able to run Kuzzle" 44


# Test - Check the existence of sysctl
#########################################

# Setup (install docker-compose)
echo " Installing docker-compose..."
docker exec -t $container /opt/test/fixtures-setupsh/install-docker-compose.sh > $output

# Check if sysctl exists
if [ -z $(docker exec -t $container sh -c 'command -v sysctl') ]; then
  docker exec -t $container \
    ./setupsh.should "fail if sysctl is not installed" "This script needs sysctl" 44
fi


# Test - Check vm_map_maxcount parameter
#########################################

# Setup (install sysctl and set bad value)
echo " Installing sysctl..."
docker exec -t $container /opt/test/fixtures-setupsh/install-sysctl.sh > $output
echo " Setting bad vm.max_map_count..."
docker exec -t $container /opt/test/fixtures-setupsh/set-map-count.sh 242144 > $output

# Check vm.max_map_count
docker exec -t $container \
  ./setupsh.should \
    "fail if vm.max_map_count is too low" \
    "The current value of the kernel configuration variable vm.max_map_count" \
    44

echo " Setting proper vm.max_map_count..."
docker exec -t $container /opt/test/fixtures-setupsh/set-map-count.sh 262144 > $output


# Test - Download docker-compose.yml
#########################################

# Setup (redirect kuzzle.io to 127.0.0.1)
echo " Killing kuzzle.io..."
docker exec -t $container sh -c 'cp /etc/hosts /etc/hosts.bak && echo "127.0.0.1 kuzzle.io" >> /etc/hosts' > $output

# Check vm.max_map_count
docker exec -t $container \
  ./setupsh.should "fail if downloading docker-compose.yml fails" "Cannot download" 45

# Teardown (clean-up /etc/hosts)
echo " Restoring kuzzle.io..."
# Note: sed -i works badly in a Docker container
docker exec -t $container cp /etc/hosts.bak /etc/hosts


# Test - Pull Kuzzle
#########################################
docker exec -t $container \
  ./setupsh.should "fail if dockerd is not running" "Pull failed." 1

echo " Launching dockerd..."
docker exec -t $container /opt/test/fixtures-setupsh/launch-dockerd.sh > $output &


# Test - Kuzzle works fine!
#########################################

docker exec -t $container \
  ./setupsh.should "run Kuzzle successfully" "Kuzzle successfully installed" 0

# all tests ok > set badge to green
curl -L https://img.shields.io/badge/setup.sh-${badge_label}-green.svg -o $badges_dir/$dist.svg

