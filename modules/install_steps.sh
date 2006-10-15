# $Id$

run_pre_install_script() {
  if [ -n "${pre_install_script_uri}" ]; then
    fetch "${pre_install_script_uri}" "${chroot_dir}/var/tmp/pre_install_script" || die "could not fetch pre-install script"
    chmod +x "${chroot_dir}/var/tmp/pre_install_script"
    spawn_chroot "/var/tmp/pre_install_script" || die "error running pre-install script"
    spawn "rm ${chroot_dir}/var/tmp/pre_install_script"
  elif $(isafunc pre_install); then
    pre_install || die "error running pre_install()"
  else
    debug run_pre_install_script "no pre-install script set"
  fi
}

partition() {
  for device in $(set | grep '^partitions_' | cut -d= -f1 | sed -e 's:^partitions_::' -e 's:_:/:g'); do
    debug partition "device is ${device}"
#    spawn "dd if=/dev/zero of=/dev/${device} bs=512 count=1" || warn "could not clear existing partition table"
    rm /tmp/install.partitions 2>/dev/null
    rm /tmp/install.format 2>/dev/null
    local device_temp="partitions_${device}"
    local device="/dev/${device}"
    for partition in $(eval echo \${${device_temp}}); do
      debug partition "partition is ${partition}"
      local minor=$(echo ${partition} | cut -d: -f1)
      local type=$(echo ${partition} | cut -d: -f2)
      local size=$(echo ${partition} | cut -d: -f3)
      local devnode="${device}${minor}"
      debug partition "devnode is ${devnode}"
      if [ "${size}" = "+" ]; then
        size=""
      else
        size=$(expr ${size} \* 2048)
      fi
      echo ",${size},${type}" >> /tmp/install.partitions
    done
    spawn "sfdisk --force -uS ${device} < /tmp/install.partitions" || die "could not partition ${device}"
  done
}

setup_md_raid() {
  for array in $(set | grep '^mdraid_' | cut -d= -f1 | sed -e 's:^mdraid_::' | sort); do
    local array_temp="mdraid_${array}"
    local arrayopts=$(eval echo \${${array_temp}})
    local arraynum=$(echo ${array} | sed -e 's:^md::')
    if [ ! -e "/dev/md${arraynum}" ]; then
      spawn "mknod /dev/md${arraynum} b 9 ${arraynum}" || die "could not create device node for array ${array}"
    fi
    spawn "mdadm --create /dev/${array} ${arrayopts}" || die "could not create array ${array}"
  done
}

format_devices() {
  for device in ${format}; do
    local devnode=$(echo ${device} | cut -d: -f1)
    local fs=$(echo ${device} | cut -d: -f2)
    local formatcmd=""
    case "${fs}" in
      swap)
        formatcmd="mkswap ${devnode}"
        ;;
      ext2)
        formatcmd="mke2fs ${devnode}"
        ;;
      ext3)
        formatcmd="mke2fs -j ${devnode}"
        ;;
      *)
        formatcmd=""
        warn "don't know how to format ${devnode} as ${fs}"
    esac
    if [ -n "${formatcmd}" ]; then
      spawn "${formatcmd}" || die "could not format ${devnode} with command: ${formatcmd}"
    fi
  done
}

mount_local_partitions() {
  if [ -z "${localmounts}" ]; then
    warn "no local mounts specified. this is a bit unusual, but you're the boss"
  else
    rm /tmp/install.mounts 2>/dev/null
    for mount in ${localmounts}; do
      debug mount_local_partitions "mount is ${mount}"
      local devnode=$(echo ${mount} | cut -d ':' -f1)
      local type=$(echo ${mount} | cut -d ':' -f2)
      local mountpoint=$(echo ${mount} | cut -d ':' -f3)
      local mountopts=$(echo ${mount} | cut -d ':' -f4)
#      [ -n "${type}" ] && type="-t ${type}"
      [ -n "${mountopts}" ] && mountopts="-o ${mountopts}"
      case "${type}" in
        swap)
          spawn "swapon ${devnode}" || warn "could not activate swap ${devnode}"
          ;;
        ext2|ext3)
          echo "mount -t ${type} ${devnode} ${chroot_dir}${mountpoint} ${mountopts}" >> /tmp/install.mounts
          ;;
      esac
    done
    sort -k5 /tmp/install.mounts | while read mount; do
      mkdir -p $(echo ${mount} | awk '{ print $5; }')
      spawn "${mount}" || die "could not mount with: ${mount}"
    done
  fi
}

mount_network_shares() {
  if [ -n "${netmounts}" ]; then
    for mount in ${netmounts}; do
      local export=$(echo ${mount} | cut -d '|' -f1)
      local type=$(echo ${mount} | cut -d '|' -f2)
      local mountpoint=$(echo ${mount} | cut -d '|' -f3)
      local mountopts=$(echo ${mount} | cut -d '|' -f4)
      [ -n "${mountopts}" ] && mountopts="-o ${mountopts}"
      case "${type}" in
        nfs)
          spawn "/etc/init.d/nfsmount start"
          mkdir -p ${chroot_dir}${mountpoint}
          spawn "mount -t nfs ${mountopts} ${export} ${chroot_dir}${mountpoint}" || die "could not mount ${type}/${export}"
          ;;
        *)
          warn "mounting ${type} is not currently supported"
      esac
    done
  fi
}

unpack_stage_tarball() {
  fetch "${stage_uri}" "${chroot_dir}/$(get_filename_from_uri ${stage_uri})" || die "Could not fetch stage tarball"
  spawn "tar -C ${chroot_dir} -xjpf ${chroot_dir}/$(get_filename_from_uri ${stage_uri})" || die "Could not unpack stage tarball"
}

prepare_chroot() {
  debug prepare_chroot "copying /etc/resolv.conf into chroot"
  spawn "cp /etc/resolv.conf ${chroot_dir}/etc/resolv.conf" || die "could not copy /etc/resolv.conf into chroot"
  debug prepare_chroot "mounting proc"
  spawn "mount -t proc none ${chroot_dir}/proc" || die "could not mount proc"
  debug prepare_chroot "bind-mounting /dev"
  spawn "mount -o bind /dev ${chroot_dir}/dev" || die "could not bind-mount /dev"
  if [ "$(uname -r | cut -d. -f 2)" = "6" ]; then
    debug prepare_chroot "bind-mounting /sys"
    spawn "mount -o bind /sys ${chroot_dir}/sys" || die "could not bind-mount /sys"
  else
    debug prepare_chroot "kernel is not 2.6...not bind-mounting /sys"
  fi
}

install_portage_tree() {
  debug install_portage_tree "tree_type is ${tree_type}"
  if [ "${tree_type}" = "sync" ]; then
    spawn_chroot "emerge --sync" || die "could not sync portage tree"
  elif [ "${tree_type}" = "snapshot" ]; then
    fetch "${portage_snapshot_uri}" "${chroot_dir}/$(get_filename_from_uri ${portage_snapshot_uri})" || die "could not fetch portage snapshot"
    spawn "tar -C ${chroot_dir}/usr -xjf ${chroot_dir}/$(get_filename_from_uri ${portage_snapshot_uri})" || die "could not unpack portage snapshot"
  elif [ "${tree_type}" = "webrsync" ]; then
    spawn_chroot "emerge-webrsync" || die "could not emerge-webrsync"
  elif [ "${tree_type}" = "none" ]; then
    warn "'none' specified...skipping"
  else
    die "Unrecognized tree_type: ${tree_type}"
  fi
}

set_root_password() {
  if [ -n "${root_password_hash}" ]; then
    spawn_chroot "echo 'root:${root_password_hash}' | chpasswd -e" || die "could not set root password"
  elif [ -n "${root_password}" ]; then
    spawn_chroot "echo 'root:${root_password}' | chpasswd -m" || die "could not set root password"
  fi
}

set_timezone() {
  [ -e "${chroot_dir}/etc/localtime" ] && spawn "rm ${chroot_dir}/etc/localtime" || die "could not remove existing /etc/localtime"
  spawn "ln -s ../usr/share/zoneinfo/${timezone} ${chroot_dir}/etc/localtime" || die "could not set timezone"
}

build_kernel() {
  spawn_chroot "emerge ${kernel_sources}" || die "could not emerge kernel sources"
  spawn_chroot "emerge genkernel" || die "could not emerge genkernel"
  if [ -n "${kernel_config_uri}" ]; then
    fetch "${kernel_config_uri}" "${chroot_dir}/tmp/kconfig" || die "could not fetch kernel config"
    spawn_chroot "genkernel --kernel-config=/tmp/kconfig ${genkernel_opts} kernel" || die "could not build custom kernel"
  else
    spawn_chroot "genkernel ${genkernel_opts} all" || die "could not build generic kernel"
  fi
}

install_logging_daemon() {
  spawn_chroot "emerge ${logging_daemon}" || die "could not emerge logging daemon"
  spawn_chroot "rc-update add ${logging_daemon} default" || die "could not add logging daemon to default runlevel"
}

install_cron_daemon() {
  if [ "${cron_daemon}" = "none" ]; then
    debug install_cron_daemon "cron_daemon is 'none'...skipping"
  else
    spawn_chroot "emerge ${cron_daemon}" || die "could not emerge cron daemon"
    spawn_chroot "rc-update add ${cron_daemon} default" || die "could not add cron daemon to default runlevel"
  fi
}

setup_network_post() {
  warn "Post-install networking setup not implemented"
}

install_bootloader() {
  if [ "${bootloader}" = "none" ]; then
    debug install_bootloader "bootloader is 'none'...skipping"
  else
    spawn_chroot "emerge ${bootloader}" || die "could not emerge bootloader"
  fi
}

configure_bootloader() {
  echo -e "default 0\ntimeout 30\n" > ${chroot_dir}/boot/grub/grub.conf
  local boot_root="$(get_boot_and_root)"
  local boot="$(echo ${boot_root} | cut -d '|' -f1)"
  local boot_device="$(get_device_and_partition_from_devnode ${boot} | cut -d '|' -f1)"
  local boot_minor="$(get_device_and_partition_from_devnode ${boot} | cut -d '|' -f2)"
  local root="$(echo ${boot_root} | cut -d '|' -f2)"
  local kernel_initrd="$(get_kernel_and_initrd)"
  for k in ${kernel_initrd}; do
    local kernel="$(echo ${k} | cut -d '|' -f1)"
    local initrd="$(echo ${k} | cut -d '|' -f2)"
    local kv="$(echo ${kernel} | sed -e 's:^.\+/kernel-::')"
    echo "title=Gentoo Linux ${kv}" >> ${chroot_dir}/boot/grub/grub.conf
    echo -en "root ($(map_device_to_grub_device ${boot_device}),$(expr ${boot_minor) - 1))\nkernel /boot/${kernel} " >> ${chroot_dir}/boot/grub/grub.conf
    if [ -z "${initrd}" ]; then
      echo "root=${root}" >> ${chroot_dir}/boot/grub/grub.conf
    else
      echo "root=/dev/ram0 init=/linuxrc ramdisk=8192 real_root=${root}" >> ${chroot_dir}/boot/grub/grub.conf
      echo -e "initrd /boot/${initrd}\n" >> ${chroot_dir}/boot/grub/grub.conf
    fi
  done
}

install_extra_packages() {
  spawn_chroot "emerge ${extra_packages}" || die "could not emerge extra packages"
}

run_post_install_script() {
  if [ -n "${post_install_script_uri}" ]; then
    fetch "${post_install_script_uri}" "${chroot_dir}/var/tmp/post_install_script" || die "could not fetch post-install script"
    chmod +x "${chroot_dir}/var/tmp/post_install_script"
    spawn_chroot "/var/tmp/post_install_script" || die "error running post-install script"
    spawn "rm ${chroot_dir}/var/tmp/post_install_script"
  elif $(isafunc post_install); then
    post_install || die "error running post_install()"
  else
    debug run_post_install_script "no post-install script set"
  fi
}

finishing_cleanup() {
  spawn "cp ${logfile} ${chroot_dir}/root/$(basename ${logfile})" || warn "could not copy install logfile into chroot"
  for mnt in $(awk '{ print $2; }' /proc/mounts | grep ^${chroot_dir} | sort -r); do
    spawn "umount ${mnt}" || warn "could not unmount ${mnt}"
  done
  for swap in $(awk '/^\// { print $1; }' /proc/swaps); do
    spawn "swapoff ${swap}" || warn "could not deactivate swap on ${swap}"
  done
}

failure_cleanup() {
  spawn "mv ${logfile} ${logfile}.failed" || warn "could not move ${logfile} to ${logfile}.failed"
  for mnt in $(awk '{ print $2; }' /proc/mounts | grep ^${chroot_dir} | sort -r); do
    spawn "umount ${mnt}" || warn "could not unmount ${mnt}"
  done
  for swap in $(awk '/^\// { print $1; }' /proc/swaps); do
    spawn "swapoff ${swap}" || warn "could not deactivate swap on ${swap}"
  done
}
