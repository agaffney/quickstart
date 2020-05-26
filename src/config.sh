#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
set -eu

install_mode() {
  mode=$1

  install_mode="${mode}"
}

part() {
  drive=$1
  minor=$2
  type=$3
  size=$4

  drive=$(echo "${drive}" | sed -e 's:^/dev/::' -e 's:/:_:g')
  drive_temp="partitions_${drive}"
  tmppart="${minor}:${type}:${size}"
  if [ -n "$(eval "echo \${${drive_temp}}")" ]; then
    eval "${drive_temp}=\"$(eval "echo \${${drive_temp}}") ${tmppart}\""
  else
    eval "${drive_temp}=\"${tmppart}\""
  fi
  debug part "${drive_temp} is now: $(eval "echo \${${drive_temp}}")"
}

mdraid() {
  array=$1
  shift
  arrayopts=$*

  eval "mdraid_${array}=\"${arrayopts}\""
}

lvm_volgroup() {
  volgroup=$1
  shift
  devices=$*

  eval "lvm_volgroup_${volgroup}=\"${devices}\""
}

lvm_logvol() {
  volgroup=$1
  size=$2
  name=$3

  tmplogvol="${volgroup}|${size}|${name}"
  if [ -n "${lvm_logvols}" ]; then
    lvm_logvols="${lvm_logvols} ${tmplogvol}"
  else
    lvm_logvols="${tmplogvol}"
  fi
}

format() {
  device=$1
  fs=$2

  tmpformat="${device}:${fs}"
  if [ -n "${format}" ]; then
    format="${format} ${tmpformat}"
  else
    format="${tmpformat}"
  fi
}

mountfs() {
  device=$1
  type=$2
  mountpoint=$3
  mountopts=$4

  [ -z "${mountopts}" ] && mountopts="defaults"
  [ -z "${mountpoint}" ] && mountpoint="none"
  tmpmount="${device}:${type}:${mountpoint}:${mountopts}"
  if [ -n "${localmounts}" ]; then
    localmounts="${localmounts} ${tmpmount}"
  else
    localmounts="${tmpmount}"
  fi
}

netmount() {
  export=$1
  type=$2
  mountpoint=$3
  mountopts=$4

  [ -z "${mountopts}" ] && mountopts="defaults"
  tmpnetmount="${export}|${type}|${mountpoint}|${mountopts}"
  if [ -n "${netmounts}" ]; then
    netmounts="${netmounts} ${tmpnetmount}"
  else
    netmounts="${tmpnetmount}"
  fi
}  

bootloader() {
  pkg=$1

  bootloader="${pkg}"
}

bootloader_kernel_args() {
  kernel_args=$1

  bootloader_kernel_args="${kernel_args}"
}

logger() {
  pkg=$1

  logging_daemon="${pkg}"
}

cron() {
  pkg=$1

  cron_daemon="${pkg}"
}

rootpw() {
  pass=$1

  root_password="${pass}"
}

rootpw_crypt() {
  pass=$1

  root_password_hash="${pass}"
}

stage_uri() {
  uri=$1

  stage_uri="${uri}"
}

tree_type() {
  type=$1
  uri=$2

  tree_type="${type}"
  portage_snapshot_uri="${uri}"
}

bootloader_install_device() {
  device=$1

  bootloader_install_device="${device}"
}

chroot_dir() {
  dir=$1

  chroot_dir="${dir}"
}

extra_packages() {
  pkg=$*

  if [ -n "${extra_packages}" ]; then
    extra_packages="${extra_packages} ${pkg}"
  else
    extra_packages="${pkg}"
  fi
}

genkernel_opts() {
  opts=$*

  genkernel_opts="${opts}"
}

kernel_config_uri() {
  uri=$1

  kernel_config_uri="${uri}"
}

kernel_sources() {
  pkg=$1

  kernel_sources="${pkg}"
}

timezone() {
  tz=$1

  timezone="${tz}"
}

rcadd() {
  service=$1
  runlevel=$2

  tmprcadd="${service}|${runlevel}"
  if [ -n "${services_add}" ]; then
    services_add="${services_add} ${tmprcadd}"
  else
    services_add="${tmprcadd}"
  fi
}

rcdel() {
  service=$1
  runlevel=$2

  tmprcdel="${service}|${runlevel}"
  if [ -n "${services_del}" ]; then
    services_del="${services_del} ${tmprcdel}"
  else
    services_del="${tmprcdel}"
  fi
}

net() {
  device=$1
  ipdhcp=$2
  gateway=$3

  tmpnet="${device}|${ipdhcp}|${gateway}"
  if [ -n "${net_devices}" ]; then
    net_devices="${net_devices} ${tmpnet}"
  else
    net_devices="${tmpnet}"
  fi
}

logfile() {
  file=$1

  logfile=${file}
}

skip() {
  func=$1
  eval "skip_${func}=1"
}

server() {
  server=$1
  server_init
}

use_linux32() {
  linux32="linux32"
}

verbose() {
  verbose=1
}

sanity_check_config() {
  fatal=0

  debug sanity_check_config "$(set | grep '^[a-z]')"

  if [ -n "${install_mode}" ] && [ "${install_mode}" != "normal" ] && [ "${install_mode}" != "chroot" ] && [ "${install_mode}" != "stage4" ]; then
    error "install_mode must be 'normal', 'chroot', or 'stage4'"
    fatal=1
  fi
  if [ -z "${chroot_dir}" ]; then
    error "chroot_dir is not defined (this can only happen if you set it to a blank string)"
    fatal=1
  fi
  if [ -z "${stage_uri}" ]; then
    error "you must specify a stage_uri"
    fatal=1
  fi
  if [ -z "${tree_type}" ]; then
    warn "tree_type not set...defaulting to sync"
    tree_type="sync"
  fi
  if [ "${tree_type}" = "snapshot" ] && [ -z "${portage_snapshot_uri}" ]; then
    error "you must specify a portage snapshot URI with tree_type snapshot"
    fatal=1
  fi
  if [ -z "${root_password}" ] && [ -z "${root_password_hash}" ]; then
    error "you must specify a root password"
    fatal=1
  fi
  if [ -z "${timezone}" ]; then
    warn "timezone not set...assuming UTC"
    timezone=UTC
  fi
  if [ -z "${kernel_sources}" ]; then
    warn "kernel_sources not set...assuming gentoo-sources"
    kernel_sources="gentoo-sources"
  fi
  if [ -z "${logging_daemon}" ]; then
    warn "logging_daemon not set...assuming syslog-ng"
    logging_daemon="syslog-ng"
  fi
  if [ -z "${cron_daemon}" ]; then
    warn "cron_daemon not set...assuming vixie-cron"
    cron_daemon="vixie-cron"
  fi

  if ! sanity_check_config_partition; then
    fatal=1
  fi
  if ! sanity_check_config_bootloader; then
    fatal=1
  fi

  debug sanity_check_config "$(set | grep '^[a-z]')"

  [ "${fatal}" = "1" ] && exit 1
}
