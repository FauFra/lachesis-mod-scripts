#!/bin/bash

function usage() {
    echo "Usage: $0 path_config.txt lower_bound_rate (optional) upper_bound_rate (optional)"
    exit 1
}

[[ -z $1 ]] && usage

PATH_CONFIG=$1
CONFIG_FILE=$PATH_CONFIG"/config.txt"
DATA_FILE=$PATH_CONFIG"/data.csv"

[[ ! -f "$CONFIG_FILE" ]] && ( echo "File $CONFIG_FILE not found"; exit 1 )



echo "> Generating csv file $DATA_FILE"
cat $CONFIG_FILE | awk '/^[0-9]/' | sed -e 's/\s\+/,/g' > $DATA_FILE


rates=($(cat $DATA_FILE | grep throughput | awk -F, '{ groups[$5]} END { PROCINFO["sorted_in"] = "@ind_str_asc"; for(g in groups) print g }')) #retrieve all rates
len_array=${#rates[@]}


if [[ $len_array < 3 ]]; 
then
    threshold_index=0
else
    threshold_index=$(($len_array-3))
fi

if [[ ! -z "$2" ]]; 
then
    threshold=$2
else
    threshold=${rates[$threshold_index]}
fi
echo "> Generating histogram plots in $PATH_CONFIG (Threshold: [$threshold, $3])"
Rscript ./lachesis-mod-scripts/reproduce/histogram_plots.r $PATH_CONFIG $threshold $3