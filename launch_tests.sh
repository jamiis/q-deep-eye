#!/bin/bash

# ./launch_tests.sh [game] [steps (million)] [slaves]
# ./launch_tests.sh breakout 5 18

game=$1
steps=$2
slaves=$3

echo $(hostname) > master_ip_address.txt
qhost > slaves_ip_addresses.txt

python organize_cluster.py $game $steps

for i in $(seq 1 $slaves); do
  echo $i
done
