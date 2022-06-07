#!/bin/bash

./fausto/manual_scripts/lachesis_do_run.sh $@ 2>&1 | tee ./data/output/manual_statistics/log/lachesis_out.log