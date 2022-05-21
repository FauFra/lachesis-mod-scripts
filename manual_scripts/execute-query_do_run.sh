#!/bin/bash

#TODO: mettere una funzione di cleanup

set -e

function cleanup(){
  for ((i=0; i<${#EXIT_COMMANDS[@]}; i++))
  do
    ${EXIT_COMMANDS[$i]}
  done
}

function usage() {
    echo "Usage: $0 --rate <rate> --duration <duration> --query <stat | etl>"
    echo "Usage: $0 --rate <rate> --duration <duration> --query <lr | vs> --kafka-host <kakfa_hostname>"
    echo "Use -h to know the others parameters"
    exit 1
}

printHelp(){
  # printf "Usage: %s --stat <statisticsHost> [OPTIONS]\n" "$0"
  # printf "OPTIONS:\n"
  # printf " %s %20s\n" "--stat" "{statisticsHost}"
  # printf " %s %54s\n" "--log" "{INFO, DEBUG, etc.} (log4j levels, DEFAULT: info)"
  # printf " %s %48s\n" "--trans" "{rt (real-time thread), nice} (DEFAULT: nice)"
  echo "--rate [REQUIRED]"
  echo "--duration [REQUIRED]"
  echo "--query [REQUIRED]"
  echo "--kafka-host [REQUIRED for lr|vs]"
  echo "--stat-host"
  echo "--java-xmx (GB)"
  exit 1
}


export STORM=BASEDIRHERE/apache-storm-1.1.0/bin/storm
export RIOT_INPUT_PROP_PATH=BASEDIRHERE/EdgeWISE-Benchmarks/Datasets/pc_resources/ 
export RIOT_RESOURCES=BASEDIRHERE/EdgeWISE-Benchmarks/Datasets/pi_resources/
export JAVA_HOME=$(ls -d /usr/lib/jvm/java-8*)


MAX_JVM_HEAP=""
RATE=""
DURATION=""
BASE_EXPERIMENT_FOLDER="BASEDIRHERE/scheduling-queries/data/output"
EXPERIMENT_FOLDER="$BASE_EXPERIMENT_FOLDER/manual_statistics/Storm/1"
UTILIZATION_STORM="./scripts/utilization-storm.sh"
STAT_HOSTNAME=""
KAFKA_HOSTNAME=""
TASKSET_CORE="0-3"
QUERY=""
EXIT_COMMANDS=()


while [ $# -gt 0 ]; do
    case $1 in    
        -h | --help)
            printHelp
            shift
            exit 0
            ;;
        --java-xmx) 
            MAX_JVM_HEAP="$2"
            shift
            ;;
        --rate)
            RATE="$2"
            shift
            ;;
        --duration)
            DURATION="$2" 
            shift
            ;;
        --stat-host)
            STAT_HOSTNAME="$2" 
            shift
            ;;
        --kafka-host)
            KAFKA_HOSTNAME="$2"
            shift
            ;;
        --query)
            QUERY="$2"
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


[[ -z $RATE ]] && usage
[[ -z $DURATION ]] && usage
[[ -z $QUERY ]] && usage
[[ ($QUERY == lr  || $QUERY == vs) && -z $KAFKA_HOSTNAME ]] && usage

# Retrieve statistics host
if [[ -z $STAT_HOSTNAME ]]; then
  STAT_HOSTNAME=$(hostname)

  if [[ $STAT_HOSTNAME == odroid* ]]; then
    STAT_HOSTNAME="odroid28"
    TASKSET_CORE="4-7"
  fi
fi
echo "> Statistics host: $STAT_HOSTNAME"

#Clear graphite
echo "> Cleaning graphite on host $STAT_HOSTNAME..."
ssh $STAT_HOSTNAME "BASEDIRHERE/scheduling-queries/scripts/clear_graphite.sh || BASEDIRHERE/scheduling-queries/scripts/clear_graphite.sh" 

#Stop utilization storm scripts
echo "> Stopping utilization storm scripts..."
# kill -n 9 $(pgrep -f "$UTILIZATION_STORM $STAT_HOSTNAME" | awk '{print $1}') || continue
UTILIZATION_COMMAND="pkill -f $UTILIZATION_STORM"
$UTILIZATION_COMMAND || true
EXIT_COMMANDS+=("$UTILIZATION_COMMAND")


if [ ! -d "$EXPERIMENT_FOLDER" ]; then
  echo "> Creating experiment folder at $EXPERIMENT_FOLDER"
  mkdir -p $EXPERIMENT_FOLDER
else
  echo "> Cleaning experiment folder $EXPERIMENT_FOLDER"
  sudo rm -rf $EXPERIMENT_FOLDER/*
fi

#Script for storm statistics (displayed in grafana)
echo "> Executing $UTILIZATION_STORM $STAT_HOSTNAME"
$UTILIZATION_STORM $STAT_HOSTNAME &

#Retrieving java max heap
[[ -n "$MAX_JVM_HEAP" ]] || { 
  temp=$(grep MemTotal /proc/meminfo | awk '{print $2/2**20}')
  MAX_JVM_HEAP=${temp%.*}
  if [ $(($MAX_JVM_HEAP % 2)) != 0 ]; then 
    MAX_JVM_HEAP=$(($MAX_JVM_HEAP + 1)) 
  fi
}
echo "> Java max heap set to $MAX_JVM_HEAP""GB"


TOTAL_TUPLES="$(( $RATE*$DURATION*60 ))"
XMX="-Xmx"$MAX_JVM_HEAP"g"
BASE_COMMAND="taskset -c $TASKSET_CORE"

if [[ $QUERY == lr || $QUERY == vs ]]; then
  if [[ $QUERY == lr ]]; then
    QR="LinearRoad"
  else
    QR="VoipStream"
  fi

  KAFKA_STOP_COMMAND="ssh -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no -o ChallengeResponseAuthentication=no $KAFKA_HOSTNAME 'pkill -f start-source.sh &>> BASEDIRHERE/scheduling-queries/kafka-source/command.log &'"
  KAFKA_START_COMMAND="ssh -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no -o ChallengeResponseAuthentication=no $KAFKA_HOSTNAME 'BASEDIRHERE/scheduling-queries/kafka-source/start-source.sh  --rate $RATE   --configFile BASEDIRHERE/scheduling-queries/storm_queries/$QR/Configurations/seqs_kafka.json --graphiteHost $STAT_HOSTNAME  &>> BASEDIRHERE/scheduling-queries/kafka-source/command.log &'"

  echo "> Stopping kafka on $KAFKA_HOSTNAME"
  echo $KAFKA_STOP_COMMAND
  eval $KAFKA_STOP_COMMAND

  sleep 3

  echo "> Starting kafka on $KAFKA_HOSTNAME"
  echo $KAFKA_START_COMMAND
  eval $KAFKA_START_COMMAND

  # trap "eval $KAFKA_STOP_COMMAND" EXIT
  EXIT_COMMANDS+=("eval $KAFKA_STOP_COMMAND")
fi

trap cleanup EXIT

if [[ $QUERY == etl ]]; then
  COMMAND="$BASE_COMMAND BASEDIRHERE/apache-storm-1.1.0/bin/storm jar BASEDIRHERE/EdgeWISE-Benchmarks/modules/storm/target/iot-bm-storm-0.1-jar-with-dependencies.jar -c metric.reporter.graphite.report.host=$STAT_HOSTNAME $XMX -Dname=Storm in.dream_lab.bm.stream_iot.storm.topo.apps.ETLTopology L ETL SYS_sample_data_senml.csv 1 1 BASEDIRHERE/EdgeWISE-Benchmarks/scripts/ etl_topology.properties ETL $TOTAL_TUPLES 1 1 --rate $RATE --statisticsFolder $EXPERIMENT_FOLDER"
elif [[ $QUERY == stat ]]; then
  COMMAND="$BASE_COMMAND BASEDIRHERE/apache-storm-1.1.0/bin/storm jar BASEDIRHERE/EdgeWISE-Benchmarks/modules/storm/target/iot-bm-storm-0.1-jar-with-dependencies.jar -c metric.reporter.graphite.report.host=$STAT_HOSTNAME $XMX -Dname=Storm in.dream_lab.bm.stream_iot.storm.topo.apps.IoTStatsTopology L STATS SYS_sample_data_senml.csv 1 1 BASEDIRHERE/EdgeWISE-Benchmarks/scripts/ stats_with_vis_topo.properties STATS $TOTAL_TUPLES 1 1 --rate $RATE --statisticsFolder $EXPERIMENT_FOLDER"        
elif [[ $QUERY == lr ]]; then
  COMMAND="$BASE_COMMAND BASEDIRHERE/apache-storm-1.2.3/bin/storm  jar BASEDIRHERE/scheduling-queries/storm_queries/LinearRoad/target/LinearRoad-1.0-SNAPSHOT.jar -c metric.reporter.graphite.report.host=$STAT_HOSTNAME $XMX -Dname=Storm LinearRoad.LinearRoad   --time $(( $DURATION*60 )) --kafkaHost $KAFKA_HOSTNAME:9092 --conf BASEDIRHERE/scheduling-queries/storm_queries/LinearRoad/Configurations/seqs_kafka.json --rate $RATE --statisticsFolder $EXPERIMENT_FOLDER --sampleLatency true"
elif [[ $QUERY == vs ]]; then
  COMMAND="$BASE_COMMAND BASEDIRHERE/apache-storm-1.2.3/bin/storm  jar BASEDIRHERE/scheduling-queries/storm_queries/VoipStream/target/VoipStream-1.0-SNAPSHOT.jar -c metric.reporter.graphite.report.host=$STAT_HOSTNAME $XMX  -Dname=Storm VoipStream.VoipStream   --time $(( $DURATION*60 )) --kafkaHost $KAFKA_HOSTNAME:9092 --conf BASEDIRHERE/scheduling-queries/storm_queries/VoipStream/Configurations/seqs_kafka.json --rate $RATE --statisticsFolder $EXPERIMENT_FOLDER --sampleLatency true"
else 
  usage
fi

printf "> Executing command: %s\n\n" "$COMMAND"
$COMMAND 2>&1 | tee $EXPERIMENT_FOLDER/etl_out.log
