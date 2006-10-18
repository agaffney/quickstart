# $Id$

get_device_size_in_mb() {
  local device=$1

  expr $(expr $(awk "/${device}$/ { print \$3; }" /proc/partitions) / 1024) - 15 # just to make sure we don't go past the end of the drive
}

human_size_to_mb() {
  local size=$1
  local device_size=$2

  debug human_size_to_mb "size=${size}, device_size=${device_size}"
  if [ "${size}" = "+" -o "${size}" = "" ]; then
    debug human_size_to_mb "size is + or blank...using rest of drive"
    size=""
    device_size=0
  else
    local number_suffix="$(echo ${size} | sed -e 's:\.[0-9]\+::' -e 's:\([0-9]\+\)\([MG%]\)B\?:\1|\2:i')"
    local number="$(echo ${number_suffix} | cut -d '|' -f1)"
    local suffix="$(echo ${number_suffix} | cut -d '|' -f2)"
    debug human_size_to_mb "number_suffix='${number_suffix}', number=${number}, suffix=${suffix}"
    case "${suffix}" in
      M|m)
        size="${number}"
        device_size="$(expr ${device_size} - ${size})"
        ;;
      G|g)
        size="$(expr ${number} \* 1024)"
        device_size="$(expr ${device_size} - ${size})"
        ;;
      %)
        size="$(expr ${device_size} \* ${number} / 100)"
        ;;
      *)
        size="-1"
        device_size="-1"
    esac
  fi
  debug human_size_to_mb "size=${size}, device_size=${device_size}"
  echo "${size}|${device_size}"
}
