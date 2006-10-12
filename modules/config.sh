# $Id$

part() {
  drive=$1
  minor=$2
  type=$3
  size=$4

  drive=$(echo ${drive} | sed -e 's:^/dev/::' -e 's:/:_:g')
  drive_temp="partitions_${drive}"
  tmppart="${minor}:${type}:${size}"
  if [ -n "$(eval echo \${${drive_temp}})" ]; then
    eval "${drive_temp}=\"$(eval echo \${${drive_temp}}) ${tmppart}\""
  else
    eval "${drive_temp}=\"${tmppart}\""
  fi
  debug part "${drive_temp} is now: $(eval echo \${${drive_temp}})"
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
  mounopts=$4

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

  tmpnetmount="${exoirt}|${type}|${mountpoint}|${mountopts}"
  if [ -n "${netmounts}" ]; then
    netmounts="${netmounts} ${tmpnetmount}"
  else
    netmounts="${tmpnetmount}"
  fi
}  

bootloader() {
  local pkg=$1

  bootloader="${pkg}"
}

logger() {
  local pkg=$1

  logging_daemon="${pkg}"
}

rootpw() {
  local pass=$1

  root_password="${pass}"
}

rootpw_crypt() {
  local pass=$1

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

sanity_check_config() {
  local fatal=0

  debug sanity_check_config "$(set)"

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
  if [ "${tree_type}" = "snapshot" -a -z "${portage_snapshot_uri}" ]; then
    error "you must specify a portage snapshot URI with tree_type snapshot"
    fatal=1
  fi
  if [ -z "${root_password}" -a -z "${root_password_hash}" ]; then
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
  if [ -z "${bootloader}" ]; then
    warn "bootloader not set...assuming grub"
    bootloader="grub"
  fi

  debug sanity_check_config "$(set)"

  [ "${fatal}" = "1" ] && exit 1
}
