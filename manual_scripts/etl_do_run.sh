#!/bin/bash


function usage() {
    echo "Usage: $0 --rate <rate> --duration <duration>"
    exit 1
}

printHelp(){
  # printf "Usage: %s --stat <statisticsHost> [OPTIONS]\n" "$0"
  # printf "OPTIONS:\n"
  # printf " %s %20s\n" "--stat" "{statisticsHost}"
  # printf " %s %54s\n" "--log" "{INFO, DEBUG, etc.} (log4j levels, DEFAULT: info)"
  # printf " %s %48s\n" "--trans" "{rt (real-time thread), nice} (DEFAULT: nice)"
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
EXPERIMENT_FOLDER="$BASE_EXPERIMENT_FOLDER/etl_statistics/StormETL/1"
UTILIZATION_STORM="./scripts/utilization-storm.sh"
HOSTNAME=""
TASKSET_CORE="0-3"


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
            HOSTNAME="$2" 
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


# Retrieve statistics host
if [[ -z $HOSTNAME ]]; then
  HOSTNAME=$(hostname)

  if [[ $HOSTNAME == odroid* ]]; then
    HOSTNAME="odroid28"
    TASKSET_CORE="4-7"
  fi
fi
echo "Statistics host: $HOSTNAME"

#Clear graphite
echo "Cleaning graphite on host $HOSTNAME..."
ssh $HOSTNAME "BASEDIRHERE/scheduling-queries/scripts/clear_graphite.sh"

#Stop utilization storm scripts
echo "Stopping utilization storm scripts..."
kill -n 9 $(pgrep -f "$UTILIZATION_STORM $HOSTNAME" | awk '{print $1}')

if [ ! -d "$EXPERIMENT_FOLDER" ]; then
  echo "Creating experiment folder at $EXPERIMENT_FOLDER"
  mkdir -p $EXPERIMENT_FOLDER
else
  echo "Cleaning experiment folder $EXPERIMENT_FOLDER"
  sudo rm -rf "$EXPERIMENT_FOLDER/*"
fi

printf "Executing %s %s\n" "$UTILIZATION_STORM" "$HOSTNAME"
$UTILIZATION_STORM $HOSTNAME &

#Retrieving java max heap
[[ -n "$MAX_JVM_HEAP" ]] || { 
  temp=$(grep MemTotal /proc/meminfo | awk '{print $2/2**20}')
  MAX_JVM_HEAP=${temp%.*}
  if [ $(($MAX_JVM_HEAP % 2)) != 0 ]; then 
    MAX_JVM_HEAP=$(($MAX_JVM_HEAP + 1)) 
  fi
}
printf "Java max heap set to %sGB\n" "$MAX_JVM_HEAP"


ELT_VALUE="$(( $RATE*$DURATION*60 ))"
XMX="-Xmx"$MAX_JVM_HEAP"g"


COMMAND="taskset -c $TASKSET_CORE BASEDIRHERE/apache-storm-1.1.0/bin/storm jar BASEDIRHERE/EdgeWISE-Benchmarks/modules/storm/target/iot-bm-storm-0.1-jar-with-dependencies.jar $XMX -Dname=Storm in.dream_lab.bm.stream_iot.storm.topo.apps.ETLTopology L ETL SYS_sample_data_senml.csv 1 1 BASEDIRHERE/EdgeWISE-Benchmarks/scripts/ etl_topology.properties ETL $ELT_VALUE 1 1 --rate $RATE --statisticsFolder $EXPERIMENT_FOLDER"

printf "Executing command: %s\n\n" "$COMMAND"
$COMMAND
