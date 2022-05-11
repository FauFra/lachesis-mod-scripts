#!/usr/bin/env bash

function usage() {
    echo "Usage: $0 #reps #duration_min"
    exit 1
}

[[ -z $1 ]] && usage
[[ -z $2 ]] && usage

REPS="$1"
DURATION="$2"
COMMIT_CODE=$(git rev-parse --short HEAD)
DATE_CODE=$(date +%j_%H%M)
EXPERIMENT_FOLDER="${COMMIT_CODE}_${DATE_CODE}"
CURRENT_ODROID=$(echo $(hostname) | tr -dc '0-9')


./scripts/run.py ./fausto/scripts/templates/StormEtlNiceRT.yaml -d "$DURATION" -r "$REPS" --statisticsHost "$(hostname)" -c "$DATE_CODE"

# ./fausto/reproduce/plot.py --plots qs-comparison qs-hist --path "data/output/$EXPERIMENT_FOLDER" > data/out/$EXPERIMENT_FOLDER/config

ssh -t pianosa "cd ~/results_experiments && ./local_scripts/download_odroid_pianosa.sh --odroid $CURRENT_ODROID --folder $EXPERIMENT_FOLDER"