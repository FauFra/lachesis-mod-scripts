#!/bin/bash

sudo cp ./lachesis-mod-scripts/rt_scripts/reboot_set_rt.service /etc/systemd/system
sudo systemctl enable reboot_set_rt
sudo systemctl start reboot_set_rt
