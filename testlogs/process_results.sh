#!/bin/bash

games='breakout pacman'
steps='6 7 8'

for game in $games; do
  for step in $steps; do
    python process_results.py $game $step
  done
done
