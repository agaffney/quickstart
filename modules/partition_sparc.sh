# $Id$

unset sanity_check_config_partition

sanity_check_config_partition() {
  warn "Sanity checking partition config for sparc"
}

create_disklabel() {
  local device=$1

  debug create_disklabel "creating new sun disklabel"
  fdisk_command ${device} "s\n0\n\n\n\n\n\n\n\n\nd\n1\nd\n2\n"
}

add_partition() {
  local device=$1
  local minor=$2
  local size=$3
  local type=$4

  first_minor="${minor}\n"
  type_minor="${minor}\n"
  [ "${minor}" = "1" ] && type_minor=""
  fdisk_command ${device} "n\n${first_minor}\n+${size}\nt\n${type_minor}${type}"
  return $?
}
