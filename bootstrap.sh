#!/usr/bin/env bash

apt-get update
apt-get install -y git vim htop

cd Human_Level_Control_through_Deep_Reinforcement_Learning/
if [ -d "torch" ]; then
    echo "Dependencies already installed"
else
    # install lua, torch, other dqn dependencies
    ./install_dependencies.sh

    # download atari 2600 rom library
    wget http://www.atarimania.com/roms/Roms.zip
    unzip Roms.zip -d roms
    rm Roms.zip
    cd roms/
    rm HARMONY\ CART\ ROMS.zip
    unzip ROMS.zip
    rm ROMS.zip
    mv ROMS/* .
    rm -rf ROMS
fi
cd ..
