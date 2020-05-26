#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
set -eu

sanity_check_config_bootloader() {
  if [ -z "${bootloader}" ]; then
    warn "bootloader not set...assuming grub"
    bootloader="grub"
  fi
}

configure_bootloader_grub() {
  printf "default 0\ntimeout 30\n" > "${chroot_dir}/boot/grub/grub.conf"
  boot_root="$(get_boot_and_root)"
  boot="$(echo "${boot_root}" | cut -d '|' -f1)"
  boot_device="$(get_device_and_partition_from_devnode "${boot}" | cut -d '|' -f1)"
  boot_minor="$(get_device_and_partition_from_devnode "${boot}" | cut -d '|' -f2)"
  root="$(echo "${boot_root}" | cut -d '|' -f2)"
  kernel_initrd="$(get_kernel_and_initrd)"

  # Clear out any existing device.map for a "clean" start
  rm "${chroot_dir}/boot/grub/device.map" > /dev/null 2>&1

  for k in ${kernel_initrd}; do
    kernel="$(echo "${k}" | cut -d '|' -f1)"
    initrd="$(echo "${k}" | cut -d '|' -f2)"
    kv="$(echo "${kernel}" | sed -e 's:^kernel-genkernel-[^-]\+-::')"
    echo "title=Gentoo Linux ${kv}" >> "${chroot_dir}/boot/grub/grub.conf"
    grub_device="$(map_device_to_grub_device "${boot_device}")"
    if [ -z "${grub_device}" ]; then
      error "could not map boot device ${boot_device} to grub device"
      return 1
    fi
    printf "root (%s,%s)\nkernel /boot/%s " "${grub_device}" "$((boot_minor-1))" "${kernel}" >> "${chroot_dir}/boot/grub/grub.conf"
    if [ -z "${initrd}" ]; then
      echo "root=${root}" >> "${chroot_dir}/boot/grub/grub.conf"
    else
      echo "root=/dev/ram0 init=/linuxrc ramdisk=8192 real_root=${root} ${bootloader_kernel_args}" >> "${chroot_dir}/boot/grub/grub.conf"
      printf "initrd /boot/%s\n" "${initrd}" >> "${chroot_dir}/boot/grub/grub.conf"
    fi
  done
  if ! spawn_chroot "grep -v rootfs /proc/mounts > /etc/mtab"; then
    error "could not copy /proc/mounts to /etc/mtab"
    return 1
  fi
  [ -z "${bootloader_install_device}" ] && bootloader_install_device="$(get_device_and_partition_from_devnode "${boot}" | cut -d '|' -f1)"
  if ! spawn_chroot "grub-install ${bootloader_install_device}"; then
    error "could not install grub to ${bootloader_install_device}"
    return 1
  fi
}
