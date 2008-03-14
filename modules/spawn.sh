# $Id$

chroot_dir=/mnt/gentoo
output_logfile=/tmp/installoutput.log

spawn() {
  local cmd=$1

  debug spawn "running command '${cmd}'"
  rm ${output_logfile}.cur 2>/dev/null
  if [ ${verbose} = 1 ]; then
    (eval "${cmd}" 2>&1; echo $? > /tmp/spawn_exitcode) | tee -a ${output_logfile} ${output_logfile}.cur
  else
    (eval "${cmd}" 2>&1; echo $? > /tmp/spawn_exitcode) | tee -a ${output_logfile} ${output_logfile}.cur >/dev/null 2>&1
  fi
  spawn_exitcode=$(</tmp/spawn_exitcode)
  rm /tmp/spawn_exitcode

  return ${spawn_exitcode}
}

spawn_chroot() {
  local cmd=$1

  debug spawn_chroot "wrapping command '${cmd}' in chroot script"
  echo -e '#!/bin/bash -l\n'${cmd}'\nexit $?' > ${chroot_dir}/var/tmp/spawn.sh
  chmod +x ${chroot_dir}/var/tmp/spawn.sh
  spawn "${linux32} chroot ${chroot_dir} /var/tmp/spawn.sh"
}
