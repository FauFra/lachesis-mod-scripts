#!/bin/bash
cd ~/lachesis-experiments
current_directory=$(pwd)
current_directory="${current_directory//"/"/"\/"}"

cd ~/lachesis-experiments/scheduling-queries
echo "[INFO] Updating paths ($current_directory)"
./update_paths.sh $current_directory