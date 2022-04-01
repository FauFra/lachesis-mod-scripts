#!/usr/bin/env python3
import sys

WARMUP_PERCENTAGE = 0.3
COOLDOWN_PERCENTAGE = 0.2

def avg(values):
  start = int(len(values)*WARMUP_PERCENTAGE)
  stop = int(len(values)*(1-COOLDOWN_PERCENTAGE))
  if(stop != len(values)):
    stop+=1
  tot = 0
  print(f'{start} {stop}')
  for i in range(start, stop):
    tot += int(values[i])

  print(tot/(stop-start))



input_len = len(sys.argv)

for i in range(1,input_len):
  file_name=sys.argv[i]
  file = open (file_name, 'r')
  print(file_name)
  values = []
  for line in file:
    value = line.split(',')
    values.append(value[-1].replace('\n', ''))
  avg(values)
  file.close()
