#!/bin/bash

# bash save_files.sh [game] [dqn_a] [dqn_b]
# bash save_files.sh breakout 17 18

echo $1 $2 $3
s3_weights_path='s3://dqn/weights'
s3_log_path='s3://dqn/logs'
game=$1
dqn_a=$2
dqn_b=$3
dqns=$dqn_a' '$dqn_b

sudo apt-get install s3cmd
# cat s3cmd_setup.txt | s3cmd --configure

cd /run/shm
ls

for dqn_number in $dqns; do
  for i in `seq 6 1 9`; do
    ec2_file='trained_'$game'_NNNN'$dqn_number'_'$i'000000.t7';
    s3_file=$game'_dqn'$dqn_number'_step'$i'000000.t7';
    s3cmd put $ec2_file $s3_weights_path'/'$s3_file;
  done
done

cd ~/src/q-deep-eye/Human_Level_Control_through_Deep_Reinforcement_Learning

for dqn_number in $dqns; do
  s3cmd put $game'_'$dqn_number'.out' $s3_log_path'/'
done
