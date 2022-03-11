#!/bin/bash

set -e

mkdir lachesis-experiments
cd lachesis-experiments
git clone https://github.com/dmpalyvos/lachesis-evaluation scheduling-queries

mv ../fausto ./scheduling-queries

#update path
current_directory=$(pwd)
current_directory="${current_directory//"/"/"\/"}"

cd ~/lachesis-experiments/scheduling-queries
echo "[INFO] Updating paths ($current_directory)"
./update_paths.sh $current_directory

#python requirements
 read -p "Do you want install minimal requirements? [y/n]: " minimal_requirement

 if [[ $minimal_requirement == "Y" ]] || [[ $minimal_requirement == "y" ]];
 then
   echo "[INFO] Installing minimal requirements"
   pip install -r requirements-minimal.txt
 else
   echo "[INFO] Installing all requirements"
   pip install -r requirements.txt
 fi

 if ! ls /usr/lib/jvm/java-8-openjdk-* &> /dev/null; then
	echo "[INFO] You have to install Java 8"
	exit
fi

#checking java version
if [[ ! $(java -version 2>&1 | grep 1.8.0_312) ]];
then
  echo "[INFO] Please, choose Java 8"
  sudo update-alternatives --config java

  echo "[INFO] Please, choose Javac 8"
  sudo  update-alternatives --config javac
fi

#checking architecture
arch=$(uname -m)
echo "[INFO] Architecture $arch"
if [[ $arch == "x86_64" ]]
then
	script="./scripts/storm_do_run.sh"
	
	echo "[INFO] Updated JAVA_HOME in $script"
	find . -path "$script" -exec perl -pi -e "s/java-8-openjdk-armhf/java-8-openjdk-amd64/g" {} +
fi

read -p "Do you want disable taskset? (It is recommended to disable it if you are not on an odroid) [y/n]: " taskset

if [[ $taskset == "Y" ]] || [[ $taskset == "y" ]]; 
then
	taskset_string_1='FORCE_STORM_TASKSET="pgrep -f Dname=Storm | xargs -I {} taskset -apc 4-7 {}"'
	taskset_string_1_repl='#FORCE_STORM_TASKSET="pgrep -f Dname=Storm | xargs -I {} taskset -apc 4-7 {}"\nFORCE_STORM_TASKSET=""'
	taskset_string_2='FORCE_LACHESIS_TASKSET="pgrep -f Dname=Lachesis | xargs -I {} sudo taskset -apc 0-3 {}"'
	taskset_string_2_repl='#FORCE_LACHESIS_TASKSET="pgrep -f Dname=Lachesis | xargs -I {} sudo taskset -apc 0-3 {}"\nFORCE_LACHESIS_TASKSET=""'
	script="./scripts/storm_do_run.sh"

	sed -i -e 's/'"$taskset_string_1"'/'"$taskset_string_1_repl"'/g' $script
	sed -i -e 's/'"$taskset_string_2"'/'"$taskset_string_2_repl"'/g' $script
	echo "[INFO] Taskset disabled"
fi

read -p "Enter SPE_LEADER_HOSTNAME: " spe_name
read -p "Enter REMOTE_GRAPHITE_HOSTNAME: " remote_name

echo "[INFO] Code compilation"
./auto_setup.sh $spe_name $remote_name