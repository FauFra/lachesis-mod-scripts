#!/usr/bin/env bash

function usage() {
    echo "Usage: $0 folder_name"
    exit 1
}

[[ -z $1 ]] && usage

./lachesis-mod-scripts/reproduce/plot.py --plots qs-comparison --path "data/output/$1" 2>&1 | tee data/output/$1/config.txt

./lachesis-mod-scripts/reproduce/r_plots.sh "data/output/$1"