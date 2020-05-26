#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
set -eu

get_arch() {
  # shellcheck disable=SC2154
  if [ -z "${linux32+x}" ]; then
    uname -m | sed -e 's:i[3-6]86:x86:' -e 's:x86_64:amd64:' -e 's:parisc:hppa:'
  else
    ${linux32} uname -m | sed -e 's:i[3-6]86:x86:' -e 's:x86_64:amd64:' -e 's:parisc:hppa:'
  fi
}

detect_disks() {
  if [ ! -d "/sys" ]; then
    error "Cannot detect disks due to missing /sys"
    exit 1
  fi
  count=0
  for i in /sys/block/[hs]d[a-z]; do
    if [ "$(cat "${i}"/removable)" = "0" ]; then
      eval "disk${count}=$(basename "${i}")"
      count=$((count+1))
    fi
  done
}

get_mac_address() {
  /sbin/ifconfig | grep HWaddr | head -n 1 | sed -e 's:^.*HWaddr ::' -e 's: .*$::'
}

unpack_tarball() {
  file=$1
  dest=$2
  preserve=$3

  tar_flags="xv"

  if [ "$preserve" = "1" ]; then
    tar_flags="${tar_flags}p"
  fi

  extension=$(echo "$file" | sed -e 's:^.*\.\([^.]\+\)$:\1:')
  case $extension in
    gz)
      tar_flags="${tar_flags}z"
      ;;
    bz2)
      tar_flags="${tar_flags}j"
      ;;
    lz*|xz*)
      tar_flags="${tar_flags}l"
      ;;
  esac

  spawn "tar -C ${dest} -${tar_flags} -f ${file}"
  return $?
}
