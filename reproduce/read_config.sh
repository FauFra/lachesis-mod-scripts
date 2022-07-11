#!/bin/bash

function usage() {
  echo "Usage: $0 file_with_abs_path variant rate"
  exit 1
}

[[ -z $1 ]] && usage
[[ -z $2 ]] && usage
[[ -z $3 ]] && usage

PTH=$1
VARIANT=$2
RATE=$3

echo $PTH $VARIANT $RATE
echo
cat $PTH | grep throughput | grep --invert-match sink-throughput | grep --invert-match NaN | grep $VARIANT | grep $RATE | awk '{sum+=$6; count++} END {print sum/count}' | xargs -I {} echo THROUGHPUT: {}
cat $PTH | grep sink-throughput | grep --invert-match NaN | grep $VARIANT | grep $RATE | awk '{sum+=$6; count++} END {print sum/count}' | xargs -I {} echo SINK-THROUGHPUT: {}
cat $PTH | grep latency | grep --invert-match end-latency | grep --invert-match NaN | grep $VARIANT | grep $RATE | awk '{sum+=$6; count++} END {print sum/count}' | xargs -I {} echo LATENCY: {}
cat $PTH | grep end-latency | grep --invert-match NaN | grep $VARIANT | grep $RATE | awk '{sum+=$6; count++} END {print sum/count}' | xargs -I {} echo END-LATENCY: {}
