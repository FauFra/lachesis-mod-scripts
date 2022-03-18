#!/bin/bash


function usage() {
    echo "Usage: $0 rate duration_min"
    exit 1
}

[[ -z $1 ]] && usage
[[ -z $2 ]] && usage

MAX_JVM_HEAP=""

RATE="$1"
DURATION="$2"
ELT_VALUE="$(( $1*$2*60 ))"
BASE_EXPERIMENT_FOLDER="BASEDIRHERE/scheduling-queries/data/output"
EXPERIMENT_FOLDER="$BASE_EXPERIMENT_FOLDER/etl_statistics/StormETL/1"

#Clear graphite
./scripts/clear_graphite.sh

if [ ! -d "$EXPERIMENT_FOLDER" ]; then
  echo "Creating experiment folder at $EXPERIMENT_FOLDER"
  mkdir -p $EXPERIMENT_FOLDER
else
  echo "Cleaning experiment folder $EXPERIMENT_FOLDER"
  sudo rm -rf "$EXPERIMENT_FOLDER/*"
fi


export STORM=BASEDIRHERE/apache-storm-1.1.0/bin/storm
export RIOT_INPUT_PROP_PATH=BASEDIRHERE/EdgeWISE-Benchmarks/Datasets/pc_resources/ 
export RIOT_RESOURCES=BASEDIRHERE/EdgeWISE-Benchmarks/Datasets/pi_resources/
export JAVA_HOME=$(ls -d /usr/lib/jvm/java-8*)


# [[ -n "$MAX_JVM_HEAP" ]] || { 
#   temp=$(grep MemTotal /proc/meminfo | awk '{print $2/2**20}')
#   MAX_JVM_HEAP=${temp%.*}
  
#   printf "Max JVM heap: %sGB\n" "$MAX_JVM_HEAP"
#   exit 1;
# }


taskset -c 0-3 BASEDIRHERE/apache-storm-1.1.0/bin/storm jar BASEDIRHERE/EdgeWISE-Benchmarks/modules/storm/target/iot-bm-storm-0.1-jar-with-dependencies.jar -Dname=Storm in.dream_lab.bm.stream_iot.storm.topo.apps.ETLTopology L ETL SYS_sample_data_senml.csv 1 1 BASEDIRHERE/EdgeWISE-Benchmarks/scripts/ etl_topology.properties ETL $ELT_VALUE 1 1 --rate $RATE --statisticsFolder $EXPERIMENT_FOLDER
