# $Id$

chroot_dir=/mnt/gentoo

spawn() {
  cmd=$1

  debug spawn "running command '${cmd}'"
  if [ ${verbose} = 1 ]; then
    eval "${cmd}" 2>&1
  else
    eval "${cmd}" &>/dev/null
  fi
}

spawn_chroot() {
  cmd=$1

  debug spawn_chroot "wrapping command '${cmd}' in chroot script"
  echo -e '#!/bin/bash -l\n'${cmd}'\nexit $?' > ${chroot_dir}/var/tmp/spawn.sh
  chmod +x ${chroot_dir}/var/tmp/spawn.sh
  spawn "chroot ${chroot_dir} /var/tmp/spawn.sh"
}
