# $Id$

sanity_check_config_bootloader() {
  if [ -z "${bootloader}" ]; then
    warn "bootloader not set...assuming silo"
    bootloader="silo"
  fi
}

configure_bootloader_silo() {
  local boot_root="$(get_boot_and_root)"
  local boot="$(echo ${boot_root} | cut -d '|' -f1)"
  local boot_device="$(get_device_and_partition_from_devnode ${boot} | cut -d '|' -f1)"
  local boot_minor="$(get_device_and_partition_from_devnode ${boot} | cut -d '|' -f2)"
  local root="$(echo ${boot_root} | cut -d '|' -f2)"
  local kernel_initrd="$(get_kernel_and_initrd)"
  echo -e "partition = ${boot_minor}\ntimeout = 300\nroot = ${root}" > ${chroot_dir}/boot/silo.conf
  for k in ${kernel_initrd}; do
    local kernel="$(echo ${k} | cut -d '|' -f1)"
    local initrd="$(echo ${k} | cut -d '|' -f2)"
    local kv="$(echo ${kernel} | sed -e 's:^kernel-genkernel-[^-]\+-::')"
    echo -e "\nimage = /boot/${kernel}" >> ${chroot_dir}/boot/silo.conf
    echo "  label = ${kv}" >> ${chroot_dir}/boot/silo.conf
    if [ -z "${initrd}" ]; then
      echo "  append = \"root=${root}\"" >> ${chroot_dir}/boot/silo.conf
    else
      echo "  append = \"root=/dev/ram0 init=/linuxrc ramdisk=8192 real_root=${root} ${bootloader_kernel_args}\"" >> ${chroot_dir}/boot/silo.conf
      echo "  initrd = /boot/${initrd}" >> ${chroot_dir}/boot/silo.conf
    fi
  done
  if ! spawn_chroot "/sbin/silo -C /boot/silo.conf"; then
    error "could not install silo"
    return 1
  fi
}

