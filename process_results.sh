#!/bin/bash

games='breakout pacman'
steps='6 7 8'

for games in $games; do
  for step in $steps; do
    echo $game
    echo $step
    #python process_results.py $game $step
  done
done
