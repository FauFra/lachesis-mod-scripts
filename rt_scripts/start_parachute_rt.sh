#!/bin/bash

function usage() {
    echo "Usage: $0 <--hrs | --mins> <value>"
    exit 1
}

printHelp(){
  echo "--hrs"
  echo "--mins"
  exit 1
}

SLEEP=""

while [ $# -gt 0 ]; do
    case $1 in    
        -h | --help)
            printHelp
            shift
            exit 0
            ;;
        --hrs) 
            SLEEP=$(($2*60*60))
            shift
            ;;
        --mins)
            SLEEP=$(($2*60))
            shift
            ;;
        --secs)
            SLEEP=$2
            shift
            ;;
        *) # End of all options.
            echo $1 not known
            shift
            exit 1
            ;;
    esac
    shift
done

if (( $(id -u)!=0 )); then
  echo "> Please run as root"
    exit
fi

[[ -n "$SLEEP" ]] || usage

chrt -r 99 sleep $SLEEP && chrt -r 99 reboot &

echo "> Sleep seconds: $SLEEP"
