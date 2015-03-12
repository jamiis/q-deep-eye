#!/usr/bin/env bash

apt-get update
apt-get install -y git vim

cd /vagrant/Human_Level_Control_through_Deep_Reinforcement_Learning/

if [ -d "torch" ]; then
    ./install_dependencies.sh
fi
