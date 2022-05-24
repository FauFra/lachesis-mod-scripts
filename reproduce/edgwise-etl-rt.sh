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
PARACHUTE_RT="sudo pkill -f start_parachute_rt.sh"

eval $PARACHUTE_RT
echo "> Starting parachute_rt script"
sudo chrt -r 99 ./fausto/rt_scripts/start_parachute_rt.sh --mins $((($DURATION*$REPS*3*9)+600)) # 600 = additiona 10 hours | 3 = OS, LACHESIS, LACHESIS-MOD | 9 = rate range 
trap "$PARACHUTE_RT" EXIT

./scripts/run.py ./fausto/scripts/templates/StormEtlNiceRT.yaml -d "$DURATION" -r "$REPS" --statisticsHost "$(hostname)" -c "$DATE_CODE"

eval $PARACHUTE_RT

ssh -t pianosa "cd ~/results_experiments && ./local_scripts/download_odroid_pianosa.sh --odroid $CURRENT_ODROID --folder $EXPERIMENT_FOLDER"