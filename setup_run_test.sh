#!/bin/bash

function usage() {
  echo "Usage: $0 kakfa_host"
  exit 1
}

[[ -z $1 ]] && usage

KAFKA_HOST="$1"

dcr="cd lachesis-experiments/scheduling-queries/grafana-graphite; docker-compose up"
zkp="screen -dm -S zookeeper bash -c 'cd; cd lachesis-experiments/kafka_2.13-2.7.0/; sudo bin/zookeeper-server-start.sh config/zookeeper.properties'"
kfk="screen -dm -S kafka bash -c 'cd; cd lachesis-experiments/kafka_2.13-2.7.0/; sudo bin/kafka-server-start.sh config/server.properties'"

ssh $(hostname) $dcr
ssh $KAFKA_HOST $zkp
sleep 1
ssh $KAFKA_HOST $kfk