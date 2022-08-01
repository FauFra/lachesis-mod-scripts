#!/bin/bash

set -e

mkdir lachesis-experiments
cd lachesis-experiments

echo "[INFO] Downloading lachesis-evaluation"
git clone https://github.com/dmpalyvos/lachesis-evaluation scheduling-queries

cp -r ../lachesis-mod-scripts ./scheduling-queries

#update path
current_directory=$(pwd)
current_directory="${current_directory//"/"/"\/"}"

cd ~/lachesis-experiments/scheduling-queries
echo "[INFO] Updating paths ($current_directory)"
./update_paths.sh $current_directory



#python requirements
 read -p "> Do you want install minimal requirements? [y/n]: " minimal_requirement

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
	# script="./scripts/storm_do_run.sh"
	
	echo "[INFO] Updated JAVA_HOME in $script"
	find . -path "*do_run.sh" -exec perl -pi -e "s/java-8-openjdk-armhf/java-8-openjdk-amd64/g" {} +
fi

read -p "Enter SPE_LEADER_HOSTNAME: " spe_name
read -p "Enter REMOTE_GRAPHITE_HOSTNAME: " remote_name

echo "[INFO] Code compilation"
./auto_setup.sh $spe_name $remote_name

echo "[INFO] Downloading Lachesis-MOD"
git clone https://github.com/FauFra/lachesis-mod
cd lachesis-mod
shopt -s extglob
mkdir lachesis
mv !(lachesis) lachesis
cd ..

echo "[INFO] Copying patch from Lachesis-MOD to Lachesis"
cp lachesis-mod/lachesis/src/main/java/io/palyvos/scheduler/integration/ExecutionController.java lachesis/lachesis/src/main/java/io/palyvos/scheduler/integration/ExecutionController.java

echo "[INFO] Compiling Lachesis-MOD"
./lachesis-mod-scripts/compile_scripts/compile_lachesis-mod.sh

echo "[INFO] Compiling Lachesis-MOD"
./lachesis-mod-scripts/compile_scripts/compile_lachesis.sh

rm -rf ~/lachesis-mod-scripts