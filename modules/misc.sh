# $Id$

get_arch() {
  ${linux32} uname -m | sed -e 's:i[3-6]86:x86:' -e 's:x86_64:amd64:' -e 's:parisc:hppa:'
}

detect_disks() {
  if [ ! -d "/sys" ]; then
    error "Cannot detect disks due to missing /sys"
    exit 1
  fi
  count=0
  for i in /sys/block/[hs]d[a-z]; do
    if [ "$(< ${i}/removable)" = "0" ]; then
      eval "disk${count}=$(basename ${i})"
      count=$(expr ${count} + 1)
    fi
  done
}

get_mac_address() {
  /sbin/ifconfig | grep HWaddr | head -n 1 | sed -e 's:^.*HWaddr ::' -e 's: .*$::'
}

unpack_tarball() {
  local file=$1
  local dest=$2
  local preserve=$3

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

