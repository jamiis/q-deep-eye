#!/bin/bash

breakout_instances='ec2-52-7-91-214.compute-1.amazonaws.com ec2-52-4-141-129.compute-1.amazonaws.com ec2-52-7-90-12.compute-1.amazonaws.com ec2-52-0-79-206.compute-1.amazonaws.com ec2-52-7-92-137.compute-1.amazonaws.com'

#'ec2-52-7-92-151.compute-1.amazonaws.com ec2-52-7-91-156.compute-1.amazonaws.com ec2-52-7-89-229.compute-1.amazonaws.com ec2-52-7-91-45.compute-1.amazonaws.com '

pacman_instances='ec2-52-1-49-70.compute-1.amazonaws.com ec2-52-7-54-242.compute-1.amazonaws.com ec2-52-7-45-99.compute-1.amazonaws.com ec2-52-7-4-66.compute-1.amazonaws.com ec2-52-6-24-18.compute-1.amazonaws.com ec2-52-5-65-130.compute-1.amazonaws.com ec2-52-5-11-143.compute-1.amazonaws.com ec2-52-7-52-157.compute-1.amazonaws.com'

game_a='1'
game_b='2'
game='pacman'

for instance in $pacman_instances; do
  python process_dqn_number.py $game $game_a $game_b 
  # cat upload_config.txt | sftp -i ~/.ssh/dqn.pem ubuntu@$instance
  cat run_saver.txt | ssh -i ~/.ssh/dqn.pem ubuntu@$instance
  game_a=$((game_a+2))
  game_b=$((game_b+2))
done

