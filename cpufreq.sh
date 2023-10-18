#!/bin/bash

# Make things safer
set -euo pipefail

# Ensure root user
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Get cpu cores count minus 1, to allow maping from 0
cpucorecount=$(grep -c processor /proc/cpuinfo)
cpucorecount=$((cpucorecount-1))

# Ensure acpi-cpufreq kernel module is loaded
if ! modprobe acpi-cpufreq; then
  pushd /lib/modules
  insmod acpi-cpufreq.ko
  popd
fi

# Set correct cpufreq governor to allow user defined frequency scaling
governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
if [ "$governor" != "userspace" ]; then
  for i in $(seq 0 "${cpucorecount}"); do
    echo userspace >/sys/devices/system/cpu/cpu"${i}"/cpufreq/scaling_governor
  done
fi

# Rereive allowed cpu freq on the system
IFS=" " read -r -a freqlist <<<"$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies)"

# Set min and max frequencies, this user overidable
scalingminfreq=${scalingminfreq:=${freqlist[-1]}}
scalingmaxfreq=${scalingmaxfreq:=${freqlist[0]}}

# This will set user defined min and max frequencies
if [ "$governor" = "userspace" ]; then
  for i in $(seq 0 "${cpucorecount}"); do
    echo "$scalingminfreq" >/sys/devices/system/cpu/cpu"${i}"/cpufreq/scaling_min_freq
    echo "$scalingmaxfreq" >/sys/devices/system/cpu/cpu"${i}"/cpufreq/scaling_max_freq
  done
fi

# Frequency scaling function
function main {
  # Get current and max cpu temps
  #currtemp=$(cat /sys/bus/platform/devices/coretemp.0/hwmon/hwmon0/temp1_input)
  #maxtemp=$(cat /sys/bus/platform/devices/coretemp.0/hwmon/hwmon0/temp1_max)
  currtemp=$(cat /sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon0/temp1_input)
  maxtemp=$(cat /sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon0/temp1_max)

  # Get average load over 5m in base10 integer format
  loadavg=$(awk -F . '{print $1 substr($2,1,2)}' </proc/loadavg)

  # Frequencies steps definitions
  minfreq=${freqlist[-1]}
  midfreq=${freqlist[$((${#freqlist[*]} / 2))]}
  maxfreq=${freqlist[0]}
  coolfreq=${freqlist[2]}

  # Set load steps to trigger frequencies scaling, this user overidable
  lowload=$(grep -c processor /proc/cpuinfo | awk '{ print $1 * 0.3 * 100 }')
  midload=$(grep -c processor /proc/cpuinfo | awk '{ print $1 * 0.6 * 100 }')

  if [ "$currtemp" -lt "$maxtemp" ]; then
    for i in $(seq 0 "${cpucorecount}"); do
      if [ "$loadavg" -le $((10#$lowload)) ]; then
        echo "Setting minfreq"
        echo "$minfreq" >/sys/devices/system/cpu/cpu"${i}"/cpufreq/scaling_setspeed
      elif [ "$loadavg" -ge $((10#$lowload)) ] && [ "$loadavg" -le $((10#$midload)) ]; then
        echo "Setting midfreq"
        echo "$midfreq" >/sys/devices/system/cpu/cpu"${i}"/cpufreq/scaling_setspeed
      elif [ "$loadavg" -ge $((10#$midload)) ]; then
        echo "Setting maxfreq"
        echo "$maxfreq" >/sys/devices/system/cpu/cpu"${i}"/cpufreq/scaling_setspeed
      fi
    done
  else
    echo "Setting coolfreq"
    for i in $(seq 0 "${cpucorecount}"); do
      echo "$coolfreq" >/sys/devices/system/cpu/cpu"${i}"/cpufreq/scaling_setspeed
    done
    sleep 30
  fi
}

function cpu_speed {
  echo Thermal status cpu temp "$(cat /sys/class/hwmon/hwmon0/device/hwmon/hwmon0/temp1_input)"
  for i in $(seq 0 "${cpucorecount}"); do
    echo cpu"${i}" "$(cat /sys/devices/system/cpu/cpu"${i}"/cpufreq/scaling_cur_freq)"
  done
}

# Deamonize the main function...
while true; do
  cpu_speed
  sleep 0.5
done