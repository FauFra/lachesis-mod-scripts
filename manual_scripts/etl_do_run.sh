#!/bin/bash


function usage() {
    echo "Usage: $0 rate duration_min"
    exit 1
}

[[ -z $1 ]] && usage
[[ -z $2 ]] && usage

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

# UTILIZATION_COMMAND="./scripts/utilization-storm.sh pianosa"
# SCHEDULER_COMMAND="  sudo java -Dname=Lachesis -cp ./lachesis/lachesis-0.1.jar io.palyvos.scheduler.integration.StormIntegration  --minPriority 19  --maxPriority -20  --statisticsFolder BASEDIRHERE/scheduling-queries/data/output/ffdb8a9_073_1901/StormETL_LACHESIS.10000/1  --statisticsHost pianosa --logarithmic --period 1 --cgroupPolicy  one --worker ETLTopology --policy metric:TASK_QUEUE_SIZE_FROM_SUBTASK_DATA:true  --queryGraph BASEDIRHERE/EdgeWISE-Benchmarks/query_graphs/etl.yaml "
# KAFKA_START_COMMAND=""
# KAFKA_STOP_COMMAND=""
# DURATION_SECONDS="300"
# STATISTICS_FOLDER="BASEDIRHERE/scheduling-queries/data/output/ffdb8a9_073_1901/StormETL_LACHESIS.10000/1"
# STATISTICS_HOST="pianosa"
# EXPERIMENT_YAML="data/output/ffdb8a9_073_1901/experiment.yaml"
# JOB_NAME="UNDEFINED"

export STORM=BASEDIRHERE/apache-storm-1.1.0/bin/storm
export RIOT_INPUT_PROP_PATH=BASEDIRHERE/EdgeWISE-Benchmarks/Datasets/pc_resources/ 
export RIOT_RESOURCES=BASEDIRHERE/EdgeWISE-Benchmarks/Datasets/pi_resources/
export JAVA_HOME=$(ls -d /usr/lib/jvm/java-8*)

# export STORM=/home/frasca/lachesis-experiments/apache-storm-1.1.0/bin/storm
# export RIOT_INPUT_PROP_PATH=/home/frasca/lachesis-experiments/EdgeWISE-Benchmarks/Datasets/pc_resources/ 
# export RIOT_RESOURCES=/home/frasca/lachesis-experiments/EdgeWISE-Benchmarks/Datasets/pi_resources/
# export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/

taskset -c 0-3 BASEDIRHERE/apache-storm-1.1.0/bin/storm jar BASEDIRHERE/EdgeWISE-Benchmarks/modules/storm/target/iot-bm-storm-0.1-jar-with-dependencies.jar -Dname=Storm in.dream_lab.bm.stream_iot.storm.topo.apps.ETLTopology L ETL SYS_sample_data_senml.csv 1 1 BASEDIRHERE/EdgeWISE-Benchmarks/scripts/ etl_topology.properties ETL $ELT_VALUE 1 1 --rate $RATE --statisticsFolder $EXPERIMENT_FOLDER
#taskset -c 4-7 /home/frasca/lachesis-experiments/apache-storm-1.1.0/bin/storm jar /home/frasca/lachesis-experiments/EdgeWISE-Benchmarks/modules/storm/target/iot-bm-storm-0.1-jar-with-dependencies.jar -Dname=Storm in.dream_lab.bm.stream_iot.storm.topo.apps.ETLTopology L ETL SYS_sample_data_senml.csv 1 1 /home/frasca/lachesis-experiments/EdgeWISE-Benchmarks/scripts/ etl_topology.properties ETL $ELT_VALUE 1 1 --rate $RATE --statisticsFolder /home/frasca/lachesis-experiments/scheduling-queries/data/output/ffdb8a9_073_1652/StormETL_OS.10000/1
