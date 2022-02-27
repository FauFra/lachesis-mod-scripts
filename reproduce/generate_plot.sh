#!/usr/bin/env bash

function usage() {
    echo "Usage: $0 folder_name"
    exit 1
}

[[ -z $1 ]] && usage

./fausto/reproduce/plot.py --plots qs-comparison latency-percentiles-legend --path "data/output/$1"