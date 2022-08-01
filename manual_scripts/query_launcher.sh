#!/bin/bash

function cleanup(){
  PID=$(pgrep -f execute-query_do_run)
  pkill -f execute-query_do_run
  wait $PID
  exit 0
}


EXPERIMENT_FOLDER="manual_statistics"
EXPERIMENT_FOLDER_PATH="./data/output/$EXPERIMENT_FOLDER"

if [ ! -d "$EXPERIMENT_FOLDER_PATH" ]; then
  echo "> Creating experiment folders at $EXPERIMENT_FOLDER_PATH"
  mkdir -p $EXPERIMENT_FOLDER_PATH/{log,csv}

else
  echo "> Cleaning experiment folders $EXPERIMENT_FOLDER_PATH"
  sudo rm -rf $EXPERIMENT_FOLDER_PATH/{log,csv}/*
fi
echo

trap cleanup EXIT

./lachesis-mod-scripts/manual_scripts/execute-query_do_run.sh $@ 2>&1 | tee ./data/output/manual_statistics/log/query_out.log &

PID=$!
wait $PID