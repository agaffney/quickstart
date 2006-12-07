# $Id$

unset sanity_check_config_partition

sanity_check_config_partition() {
  warn "Sanity checking partition config for sparc"
}

create_disklabel() {
  local device=$1

  debug create_disklabel "creating new sun disklabel"
  spawn "dd if=/dev/zero of=${device} bs=512 count=1" || die "couldn't clear first block"
  fdisk_command ${device} "0\n\n\n\n\n\n\n\n\nd\n1\nd\n2\n"
  return $?
}

get_partition_end() {
  local device=$1
  local minor=$2

  fdisk -l ${device} | grep "^${device}${minor}" | awk '{ if ( $2 ~ /^[0-9]+$/ ) print $3; else print $4; }'
}

add_partition() {
  local device=$1
  local minor=$2
  local size=$3
  local type=$4

  local start
  if [ "${minor}" = "1" ]; then
    start=1
  elif [ "${minor}" = "4" ]; then
    start=$(get_partition_end ${device} 2)
  else
    start=$(get_partition_end ${device} $(expr ${minor} - 1))
  fi
  size="+${size}"
  [ "${size}" = "+" ] && size=""
  fdisk_command ${device} "n\n${minor}\n${start}\n${size}\nt\n${minor}\n${type}"
  return $?
}
