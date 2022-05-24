#!/bin/bash

echo 1000000 > /proc/sys/kernel/sched_rt_period_us
echo 950000 > /proc/sys/kernel/sched_rt_runtime_us
echo 1000000 > /sys/fs/cgroup/cpu,cpuacct/cpu.rt_period_us
echo 950000 > /sys/fs/cgroup/cpu,cpuacct/cpu.rt_runtime_us
echo 950000 > /sys/fs/cgroup/cpu,cpuacct/user.slice/cpu.rt_runtime_us
