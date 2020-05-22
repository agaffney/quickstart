#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
set -eu

get_device_size_in_mb() {
  device=$1

  if [ -h "${device}" ]; then
    device=$(readlink "${device}")
  fi
  device=$(echo "${device}" | sed -e 's:^/dev/::;s:/:\\/:g')
  partition_sizes=$(grep "${device}" /proc/partitions | awk '{ print $3 }')
  for size in $partition_sizes; do
    sum=$((sum+size))
  done
  echo $(((sum/1024)-2))
}

human_size_to_mb() {
  size=$1
  device_size=$2

  debug human_size_to_mb "size=${size}, device_size=${device_size}"
  if [ "${size}" = "+" ] || [ "${size}" = "" ]; then
    debug human_size_to_mb "size is + or blank...using rest of drive"
    size=""
    device_size=0
  else
    number_suffix="$(echo "${size}" | sed -e 's:\.[0-9]\+::' -e 's:\([0-9]\+\)\([MmGg%]\)[Bb]\?:\1|\2:')"
    number="$(echo "${number_suffix}" | cut -d '|' -f1)"
    suffix="$(echo "${number_suffix}" | cut -d '|' -f2)"
    debug human_size_to_mb "number_suffix='${number_suffix}', number=${number}, suffix=${suffix}"
    case "${suffix}" in
      M|m)
        size="${number}"
        device_size="$((device_size-size))"
        ;;
      G|g)
        size="$((number*1024))"
        device_size="$((device_size-size))"
        ;;
      %)
        size="$((device_size*number/100))"
        ;;
      *)
        size="-1"
        device_size="-1"
    esac
  fi
  debug human_size_to_mb "size=${size}, device_size=${device_size}"
  echo "${size}|${device_size}"
}

format_devnode() {
  device=$1
  partition=$1
  devnode=""

  if echo "${device}" | grep -q '[0-9]$'; then
    devnode="${device}p${partition}"
  else
    devnode="${device}${partition}"
  fi
  echo "${devnode}"
}

fdisk_command() {
  device=$1
  cmd=$2

  debug fdisk_command "running fdisk command '${cmd}' on device ${device}"
  spawn "echo -en '${cmd}\nw\n' | fdisk ${device}"
  return $?
}

sanity_check_config_partition() {
  debug sanity_check_config_partition "no arch-specific partitioning config sanity check function"
}

arch=$(get_arch)
if [ -f "modules/${arch}/partition.sh" ]; then
  debug partition.sh "loading ${arch}-specific partition module"
  import "${arch}/partition"
fi
