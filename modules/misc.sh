# $Id$

get_arch() {
  uname -m | sed -e 's:i[3-6]86:x86:' -e 's:x86_64:amd64:' -e 's:parisc:hppa:'
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
  /sbin/ifconfig | grep HWaddr | head -n 1 | sed -e 's:^.*HWaddr ::'
}
