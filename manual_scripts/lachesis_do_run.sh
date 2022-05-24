#!/bin/bash

STATISTICS_HOST=""
LOG="INFO"
TRANSLATOR="nice"
MIN_PRIORITY="19"
MAX_PRIORITY="-20"
PERIOD="1000"
TASKSET_CORE="4-5"
LACHESIS_VERSION="lachesis"
QUERY=""
METRIC="INPUT_OUTPUT_EXTERNAL_QUEUE_SIZE"


usage(){
  echo "Usage: $0 --stat <statisticsHost> --query <etl | stat | lr>"
  exit 1
}

printHelp(){
  # printf "Usage: %s --stat <statisticsHost> [OPTIONS]\n" "$0"
  # printf "OPTIONS:\n"
  # printf " %s %20s\n" "--stat" "{statisticsHost}"
  # printf " %s %54s\n" "--log" "{INFO, DEBUG, etc.} (log4j levels, DEFAULT: info)"
  # printf " %s %48s\n" "--trans" "{rt (real-time thread), nice} (DEFAULT: nice)"
  # exit 1
  echo "--stat [REQUIRED]"
  echo "--query <etl | stat | lr | vs> [REQUIRED]"
  echo "--metric <io (INPUT_OUTPUT_QUEUE_SIZE) | ioe (INPUT_OUTPUT_EXTERNAL_QUEUE_SIZE) | ts (TASK_QUEUE_SIZE_FROM_SUBTASK_DATA)>"
  echo "--log"
  echo "--transl"
  echo "--period"
  echo "--mod"
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
        --period)
            PERIOD="$2"
            shift
            ;;
        --mod)
            LACHESIS_VERSION="lachesis-mod"
            ;;
        --query)
            QUERY="$2"
            shift
            ;;
        --transl)
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
        --metric)
          if [[ "$2" == "io"  ]]; then
            METRIC="INPUT_OUTPUT_QUEUE_SIZE"
          elif [[ "$2" == "ioe" ]]; then
            METRIC="INPUT_OUTPUT_EXTERNAL_QUEUE_SIZE"
          elif [[ "$2" == "iok" ]]; then  
            METRIC="INPUT_OUTPUT_KAFKA_QUEUE_SIZE"
          elif [[ "$2" == "ts" ]]; then
            METRIC="TASK_QUEUE_SIZE_FROM_SUBTASK_DATA"
          else
            printf "Metric %s unknown\n" "$2"
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

[[ -n "$STATISTICS_HOST" ]] || usage
[[ -n "$QUERY" ]] || usage

if [[ $(hostname) == odroid* ]]; then 
	TASKSET_CORE="0-3" 
fi

if [[ $QUERY == etl ]]; then
  WORKER="ETLTopology"
  QUERY_GRAPHS="BASEDIRHERE/EdgeWISE-Benchmarks/query_graphs/etl.yaml"
elif [[ $QUERY == stat ]]; then
  WORKER="IoTStatsTopology"
  QUERY_GRAPHS="BASEDIRHERE/EdgeWISE-Benchmarks/query_graphs/stats.yaml"
elif [[ $QUERY == lr ]]; then
  WORKER="LinearRoad"
  QUERY_GRAPHS="BASEDIRHERE/scheduling-queries/storm_queries/LinearRoad/linear_road.yaml"
elif [[ $QUERY == vs ]]; then
  WORKER="VoipStream"
  QUERY_GRAPHS="BASEDIRHERE/scheduling-queries/storm_queries/VoipStream/voip_stream.yaml"
else
  usage
fi

if [ -z "$METRIC" ]; then
  if [[ $QUERY == vs || $QUERY == lr ]]; then
    METRIC="INPUT_OUTPUT_KAFKA_QUEUE_SIZE"
  else
    METRIC="INPUT_OUTPUT_EXTERNAL_QUEUE_SIZE"
  fi
fi


COMMAND="taskset -c $TASKSET_CORE sudo java -Dname=Lachesis -cp ./$LACHESIS_VERSION/lachesis-0.1.jar io.palyvos.scheduler.integration.StormIntegration  --translator $TRANSLATOR  --minPriority $MIN_PRIORITY  --maxPriority $MAX_PRIORITY  --statisticsFolder BASEDIRHERE/scheduling-queries/data/output/manual_statistics/Storm/1  --statisticsHost $STATISTICS_HOST --logarithmic --period $PERIOD --cgroupPolicy  one --worker $WORKER --policy metric:$METRIC:true  --queryGraph $QUERY_GRAPHS --log $LOG  --cgroupPeriod 1000"



printf "Executing command: %s\n\n" "$COMMAND"
$COMMAND 2>&1 | tee BASEDIRHERE/scheduling-queries/data/output/manual_statistics/Storm/1/lachesis_out.log
