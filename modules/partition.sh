# $Id$

get_device_size_in_mb() {
  local device=$1

  expr $(awk "/${device}$/ { print \$3; }" /proc/partitions) / 1024
}
