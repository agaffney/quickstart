# $Id$

unset sanity_check_config_partition

sanity_check_config_partition() {
  warn "Sanity checking partition config for x86"
}

create_disklabel() {
  local device=$1

  debug create_disklabel "creating new msdos disklabel"
  fdisk_command ${device} "o"
  return $?
}

get_num_primary() {
  local device=$1

  local primary_count=0
  local device_temp="partitions_$(echo ${device} sed -e 's:^.\+/::')"
  for partition in $(eval echo \${${device_temp}}); do
    debug get_num_primary "partition is ${partition}"
    local minor=$(echo ${partition} | cut -d: -f1)
    if [ "${minor}" < "5" ]; then
      primary_count=$(expr ${primary_count} + 1)
      debug get_num_primary "primary_count is ${primary_count}"
    fi
  done
  echo ${primary_count}
}

add_partition() {
  local device=$1
  local minor=$2
  local size=$3
  local type=$4

  if [ "${minor}" < "5" ]; then
    primary_extended="p\n"
    first_minor="${minor}\n"
    [ "${minor}" = "4" ] && first_minor=""
    type_minor="${minor}\n"
    [ "${minor}" = "1" ] && type_minor=""
  else
    # Extended partitions
    first_minor="${minor}\n"
    type_minor="${minor}\n"
    primary_extended="e\n"
    [ "$(get_num_primary ${device})" > "3" ] && primary_extended=""
  fi
  fdisk_command ${device} "n\n${primary_extended}${first_minor}\n+${size}\nt\n${type_minor}${type}\n"
  return $?
}
