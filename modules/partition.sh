# $Id$

get_device_size_in_mb() {
  local device=$1

  expr $(expr $(awk "/${device}$/ { print \$3; }" /proc/partitions) / 1024) - 15 # just to make sure we don't go past the end of the drive
}
