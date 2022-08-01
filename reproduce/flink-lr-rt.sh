#!/usr/bin/env bash

function usage() {
    echo "Usage: $0 #reps #duration_min kafka_host"
    exit 1
}

[[ -z $1 ]] && usage
[[ -z $2 ]] && usage
[[ -z $3 ]] && usage

REPS="$1"
DURATION="$2"
KAFKA_HOST="$3"
DATE_CODE=$(date +%j_%H%M)
COMMIT_CODE=$(git rev-parse --short HEAD)
EXPERIMENT_FOLDER="${COMMIT_CODE}_${DATE_CODE}"
CURRENT_ODROID=$(echo $(hostname) | tr -dc '0-9')
PARACHUTE_RT="sudo pkill -f start_parachute_rt.sh"

../flink-1.11.2/bin/stop-cluster.sh

echo "> Starting parachute_rt script"
sudo chrt -r 99 ./lachesis-mod-scripts/rt_scripts/start_parachute_rt.sh --mins $((($DURATION*$REPS*3*7)+240)) # 240 = additional 4 hours | 3 = OS, LACHESIS, LACHESIS-MOD | 8 = rate range 
trap "$PARACHUTE_RT" EXIT

./scripts/run.py ./lachesis-mod-scripts/scripts/templates/FlinkLinearRoadKafkaRT.yaml -d "$DURATION" -r "$REPS" --statisticsHost "$(hostname)" --kafkaHost "$KAFKA_HOST" -c "$DATE_CODE" --sampleLatency true

eval $PARACHUTE_RT

ssh -t pianosa "cd ~/results_experiments && ./local_scripts/download_odroid_pianosa.sh --odroid $CURRENT_ODROID --folder $EXPERIMENT_FOLDER"

