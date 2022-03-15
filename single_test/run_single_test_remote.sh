#!/usr/bin/env bash

function usage() {
  echo "Usage: $0 rate variant #reps #duration_min kakfa_host graphite_host"
  exit 1
}

[[ -z $1 ]] && usage
[[ -z $2 ]] && usage
[[ -z $3 ]] && usage
[[ -z $4 ]] && usage
[[ -z $5 ]] && usage
[[ -z $6 ]] && usage

RATE="$1"
VARIANT="$2"
REPS="$3"
DURATION="$4"
KAFKA_HOST="$5"
GRAPHITE_HOST="$6"
DATE_CODE=$(date +%j_%H%M)
COMMIT_CODE=$(git rev-parse --short HEAD)
EXPERIMENT_FOLDER="${COMMIT_CODE}_${DATE_CODE}"

./fausto/single_test/create_configuration.py ./fausto/single_test/template.yaml -r $RATE -v "$VARIANT"

../flink-1.11.2/bin/stop-cluster.sh

./scripts/run.py ./fausto/single_test/config.yaml -d "$DURATION" -r "$REPS" --statisticsHost "$GRAPHITE_HOST" --kafkaHost "$KAFKA_HOST" -c "$DATE_CODE" --sampleLatency true

unlink ./fausto/single_test/config.yaml

./fausto/reproduce/generate_plot.sh $EXPERIMENT_FOLDER
#./reproduce/plot.py --plots qs-comparison latency-percentiles-legend --path "data/output/$EXPERIMENT_FOLDER"
