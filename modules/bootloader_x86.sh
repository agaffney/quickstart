# $Id$

sanity_check_config_bootloader() {
  if [ -z "${bootloader}" ]; then
    warn "bootloader not set...assuming grub"
    bootloader="grub"
  fi
}

configure_bootloader_grub() {
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
    local kv="$(echo ${kernel} | sed -e 's:^kernel-genkernel-[^-]\+-::')"
    echo "title=Gentoo Linux ${kv}" >> ${chroot_dir}/boot/grub/grub.conf
    local grub_device="$(map_device_to_grub_device ${boot_device})"
    if [ -z "${grub_device}" ]; then
      error "could not map boot device ${boot_device} to grub device"
      return 1
    fi
    echo -en "root (${grub_device},$(expr ${boot_minor} - 1))\nkernel /boot/${kernel} " >> ${chroot_dir}/boot/grub/grub.conf
    if [ -z "${initrd}" ]; then
      echo "root=${root}" >> ${chroot_dir}/boot/grub/grub.conf
    else
      echo "root=/dev/ram0 init=/linuxrc ramdisk=8192 real_root=${root} ${bootloader_kernel_args}" >> ${chroot_dir}/boot/grub/grub.conf
      echo -e "initrd /boot/${initrd}\n" >> ${chroot_dir}/boot/grub/grub.conf
    fi
  done
  if ! spawn_chroot "grep -v rootfs /proc/mounts > /etc/mtab"; then
    error "could not copy /proc/mounts to /etc/mtab"
    return 1
  fi
  [ -z "${bootloader_install_device}" ] && bootloader_install_device="$(get_device_and_partition_from_devnode ${boot} | cut -d '|' -f1)"
  if ! spawn_chroot "grub-install ${bootloader_install_device}"; then
    error "could not install grub to ${bootloader_install_device}"
    return 1
  fi
}

