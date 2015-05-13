#!/bin/bash

M_IPS='52.7.238.85'

IPS=('52.7.215.166' '52.0.192.49' '52.5.26.185' '52.7.246.229' '52.7.234.186' '52.7.239.130' '52.7.253.253' '52.7.237.152' '52.7.130.143' '52.5.213.196' '52.4.152.8' '52.7.18.125') 

#IPS=('52.4.250.247' '52.7.225.163' '52.7.31.110' '52.7.56.1' '52.6.225.216' '52.7.19.27')


GAME="pacman"
STEP="9000000"
PORT=2005

cmd1='cd src/q-deep-eye/Human_Level_Control_through_Deep_Reinforcement_Learning'
cmd2="nohup ./run_master ${GAME} ${PORT} SELF "`echo ${IPS[*]}`">${GAME}_step${STEP}_nn${#IPS[*]}.out &"

ssh -i ~/.ssh/dqn.pem ubuntu@$M_IPS "$cmd1; $cmd2"
