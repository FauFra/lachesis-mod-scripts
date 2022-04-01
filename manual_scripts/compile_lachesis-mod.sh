#!/bin/bash

echo Compiling lachesis...
cd lachesis-mod/lachesis
echo $(pwd)
mvn clean package
cp target/lachesis-0.1.jar ..
