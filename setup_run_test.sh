#!/bin/bash

function usage() {
  echo "Usage: $0 kakfa_host"
  exit 1
}

[[ -z $1 ]] && usage

KAFKA_HOST="$1"

kill_screen="screen -dm -S scrn bash -c 'killall screen'"
kill_graphite="screen -dm -S graphite bash -c 'docker stop graphite'"
dcr="screen -dm -S docker bash -c 'cd lachesis-experiments/scheduling-queries/grafana-graphite; sudo docker-compose up'"
zkp="screen -dm -S zookeeper bash -c 'cd; cd lachesis-experiments/kafka_2.13-2.7.0/; sudo bin/zookeeper-server-start.sh config/zookeeper.properties'"
kfk="screen -dm -S kafka bash -c 'cd; cd lachesis-experiments/kafka_2.13-2.7.0/; sudo bin/kafka-server-start.sh config/server.properties'"

echo Shutdown graphite on $(hostname)
ssh $(hostname) $kill_graphite
echo Shutdown screen sessions on $KAFKA_HOST
ssh $KAFKA_HOST $kill_screen
# sleep 2

echo Starting graphite on $(hostname)
ssh $(hostname) $dcr

echo Starting zookeeper on $KAFKA_HOST
ssh $KAFKA_HOST $zkp
sleep 2.5
echo Starting kafka on $KAFKA_HOST
ssh $KAFKA_HOST $kfk