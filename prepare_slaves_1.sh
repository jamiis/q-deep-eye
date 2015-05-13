#!/bin/bash

IPS=('52.7.215.166' '52.0.192.49' '52.5.26.185' '52.7.246.229' '52.7.234.186' '52.7.239.130' '52.7.253.253' '52.7.237.152' '52.7.130.143' '52.5.213.196' '52.4.152.8' '52.7.18.125') 

#IPS=('52.4.250.247' '52.7.225.163' '52.7.31.110' '52.7.56.1' '52.6.225.216' '52.7.19.27')

GAME="pacman"
STEP="9000000"
PORT=2005
RUN_INDICES=`seq 1 12`

for i in ${RUN_INDICES[*]}; do
    echo $i
    ii=$i
    if [ $i -lt 10 ] ; then
        ii="0"$i
    fi
    WEIGHTFILE="${GAME}_dqn${ii}_step${STEP}.t7"
    cmd1='cd src/q-deep-eye/Human_Level_Control_through_Deep_Reinforcement_Learning'
    cmd2="s3cmd get s3://dqn/weights/${WEIGHTFILE} dqn/"
    cmd3="nohup ./run_slave ${GAME} ${WEIGHTFILE}  ${PORT} > ${GAME}_${STEP}_nn${#RUN_INDICES[*]}_dqn${i}.out &"
    cmd4="git pull"
    IP=${IPS[$(($i-1))]}
    ssh -i ~/.ssh/dqn.pem ubuntu@$IP "$cmd1; $cmd2; $cmd3 "
done
