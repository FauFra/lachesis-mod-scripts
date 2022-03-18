#!/bin/bash

STATISTICS_HOST=""
LOG="INFO"
TRANSLATOR="nice"
MIN_PRIORITY="19"
MAX_PRIORITY="-20"

printHelp(){
  printf "Usage: %s --stat <statisticsHost> [OPTIONS]\n" "$0"
  printf "OPTIONS:\n"
  printf " %s %20s\n" "--stat" "{statisticsHost}"
  printf " %s %54s\n" "--log" "{INFO, DEBUG, etc.} (log4j levels, DEFAULT: info)"
  printf " %s %48s\n" "--trans" "{rt (real-time thread), nice} (DEFAULT: nice)"
  exit 1
}

while [ $# -gt 0 ]; do
    case $1 in    
        -h | --help)
            printHelp
            shift
            exit 0
            ;;
        --stat) 
            STATISTICS_HOST="$2"
            shift
            ;;
        --log)
            LOG="$2"
            shift
            ;;
        --trans)
            if [[ "$2" == "rt" ]]; then
              TRANSLATOR="real-time"
              MIN_PRIORITY="1"
              MAX_PRIORITY="99"
            elif [[ "$2" == "np" ]]; then
              TRANSLATOR="noop"
            elif [[ "$2" == "nc" ]]; then
              TRANSLATOR="nice"
              MIN_PRIORITY="19"
              MAX_PRIORITY="-20"
            else
              printf "Translator %s unknown\n" "$2"
              exit 1
            fi
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

[[ -n "$STATISTICS_HOST" ]] || { echo "Please provide statistics host with --stat <statisticsHost>"; exit 1; }

COMMAND="taskset -c 4-5 sudo java -Dname=Lachesis -cp ./lachesis/lachesis-0.1.jar io.palyvos.scheduler.integration.StormIntegration  --translator $TRANSLATOR  --minPriority $MIN_PRIORITY  --maxPriority $MAX_PRIORITY  --statisticsFolder BASEDIRHERE/scheduling-queries/data/output/etl_statistics/StormETL/1  --statisticsHost $STATISTICS_HOST --logarithmic --period 1 --cgroupPolicy  one --worker ETLTopology --policy metric:TASK_QUEUE_SIZE_FROM_SUBTASK_DATA:true  --queryGraph BASEDIRHERE/EdgeWISE-Benchmarks/query_graphs/etl.yaml --log $LOG  --cgroupPeriod 1"

printf "Executing command: %s\n\n" "$COMMAND"
$COMMAND
#taskset -c 0-3 sudo java -Dname=Lachesis -cp ./lachesis/lachesis-0.1.jar io.palyvos.scheduler.integration.StormIntegration  --minPriority 19  --maxPriority -20  --statisticsFolder /home/frasca/lachesis-experiments/scheduling-queries/data/output/ffdb8a9_074_0937/StormETL_LACHESIS.10000/1  --statisticsHost pianosa --logarithmic --period 1 --cgroupPolicy  one --worker ETLTopology --policy metric:TASK_QUEUE_SIZE_FROM_SUBTASK_DATA:true  --queryGraph /home/frasca/lachesis-experiments/EdgeWISE-Benchmarks/query_graphs/etl.yaml