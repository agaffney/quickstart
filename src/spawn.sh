#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
set -eu

chroot_dir="/mnt/gentoo"
output_logfile="/tmp/installoutput.log"

spawn() {
  cmd=$1

  debug spawn "running command '${cmd}'"
  rm ${output_logfile}.cur 2>/dev/null
  if [ "${verbose}" = "1" ]; then
    (eval "${cmd}" 2>&1; echo $? > /tmp/spawn_exitcode) | tee -a ${output_logfile} ${output_logfile}.cur
  else
    (eval "${cmd}" 2>&1; echo $? > /tmp/spawn_exitcode) | tee -a ${output_logfile} ${output_logfile}.cur >/dev/null 2>&1
  fi
  spawn_exitcode=$(cat /tmp/spawn_exitcode)
  rm /tmp/spawn_exitcode

  return "${spawn_exitcode}"
}

spawn_chroot() {
  cmd=$1

  debug spawn_chroot "wrapping command '${cmd}' in chroot script"
  printf '#!/bin/bash -l\n%s\nexit $?' "${cmd}" > "${chroot_dir}/var/tmp/spawn.sh"
  chmod +x ${chroot_dir}/var/tmp/spawn.sh
  spawn "${linux32} chroot ${chroot_dir} /var/tmp/spawn.sh"
}
