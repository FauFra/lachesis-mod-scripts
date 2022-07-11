#!/usr/bin/env bash

function usage() {
    echo "Usage: $0 folder_name"
    exit 1
}

[[ -z $1 ]] && usage

./fausto/reproduce/plot.py --plots qs-comparison --path "data/output/$1" 2>&1 | tee data/output/$1/config.txt

./fausto/reproduce/r_plots.sh "data/output/$1"