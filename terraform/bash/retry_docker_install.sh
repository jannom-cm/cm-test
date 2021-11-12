#!/bin/bash
is_docker=`dpkg -l | grep docker-ce | wc -l` 
if [ "$is_docker" -gt 1 ];
then
    echo "ok docker-ce is there, no need to re-try"
else
    echo  "docker-ce is missing, now retrying..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs)  stable"
    sudo apt-get update &&  sudo apt-get --assume-yes install docker-ce -y
fi
