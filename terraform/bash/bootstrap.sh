#!/bin/bash

sudo apt-get --assume-yes install python3  python3-requests 
sudo apt-get --assume-yes install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs)  stable"
sudo apt-get update && sudo apt-get install --assume-yes docker-ce 
sudo apt-get --assume-yes install python3-prometheus-client
