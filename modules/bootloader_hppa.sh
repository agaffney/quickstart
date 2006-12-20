# $Id$

sanity_check_config_bootloader() {
  if [ -z "${bootloader}" ]; then
    warn "bootloader not set...assuming palo"
    bootloader="palo"
  fi
}

configure_bootloader_palo() {
  local boot_root="$(get_boot_and_root)"
  local boot="$(echo ${boot_root} | cut -d '|' -f1)"
  local boot_device="$(get_device_and_partition_from_devnode ${boot} | cut -d '|' -f1)"
  local boot_minor="$(get_device_and_partition_from_devnode ${boot} | cut -d '|' -f2)"
  local root="$(echo ${boot_root} | cut -d '|' -f2)"
  local kernel_initrd="$(get_kernel_and_initrd | cut -f1)" # We only want the newest kernel/initrd
  echo "--init-partitioned=${boot_device}" > ${chroot_dir}/etc/palo.conf
  local kernel="$(echo ${kernel_initrd} | cut -d '|' -f1)"
  local initrd="$(echo ${kernel_initrd} | cut -d '|' -f2)"
  local kv="$(echo ${kernel} | sed -e 's:^kernel-genkernel-[^-]\+-::')"
  echo -n "--commandline=${boot_minor}/boot/${kernel} " >> ${chroot_dir}/etc/palo.conf
  if [ -z "${initrd}" ]; then
    echo "root=${root}" >> ${chroot_dir}/etc/palo.conf
  else
    echo "root=/dev/ram0 init=/linuxrc ramdisk=8192 real_root=${root} initrd=${boot_minor}/boot/${initrd}" >> ${chroot_dir}/etc/palo.conf
  fi
  if ! spawn_chroot "/sbin/palo"; then
    error "could not install palo"
    return 1
  fi
}

