#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
set -eu

map_device_to_grub_device() {
  device=$1

  # shellcheck disable=SC2154
  if [ ! -f "${chroot_dir}/boot/grub/device.map" ]; then
    debug map_device_to_grub_device "device.map doesn't exist...creating"
    spawn_chroot "echo quit | /sbin/grub --batch --no-floppy --device-map=/boot/grub/device.map >/dev/null 2>&1" || die "could not create grub device map"
  fi
  grep "${device}\$" "${chroot_dir}/boot/grub/device.map" | awk '{ print $1; }' | sed -e 's:[()]::g'
}

get_kernel_and_initrd() {
  kernels=""
  for kernel in "${chroot_dir}"/boot/kernel-*; do
    kernel="$(echo "${kernel}" | sed -e 's:^.\+/kernel-:kernel-:')"
    if [ -e "${chroot_dir}/boot/$(echo "${kernel}" | sed -e 's:kernel-:initrd-:')" ]; then
      initrd="$(echo "${kernel}" | sed -e 's:kernel-:initrd-:')"
    elif [ -e "${chroot_dir}/boot/$(echo "${kernel}" | sed -e 's:kernel-:initramfs-:')" ]; then
      initrd="$(echo "${kernel}" | sed -e 's:kernel-:initramfs-:')"
    fi
    if [ -n "${kernels}" ]; then
      kernels="${kernels} ${kernel}|${initrd}"
    else
      kernels="${kernel}|${initrd}"
    fi
  done
  echo "${kernels}"
}

get_boot_and_root() {
  # shellcheck disable=SC2154
  for mount in ${localmounts}; do
    devnode=$(echo "${mount}" | cut -d ':' -f1)
    mountpoint=$(echo "${mount}" | cut -d ':' -f3)
    if [ "${mountpoint}" = "/" ]; then
      root="${devnode}"
    elif [ "${mountpoint}" = "/boot" ] || [ "${mountpoint}" = "/boot/" ]; then
      boot="${devnode}"
    fi
  done
  if [ -z "${boot}" ]; then
    boot="${root}"
  fi
  echo "${boot}|${root}"
}

get_device_from_devnode() {
  devnode=$1

  echo "${devnode}" | sed -e 's:p\?[0-9]\+$::'
}

get_device_and_partition_from_devnode() {
  devnode=$1

  echo "${devnode}" | sed -e 's:p\?\([0-9]\+\)$:|\1:'
}

sanity_check_config_bootloader() {
  debug sanity_check_config_bootloader "no arch-specific bootloader config sanity check function"
}

arch=$(get_arch)
if [ -f "modules/${arch}/bootloader.sh" ]; then
  debug bootloader.sh "loading ${arch}-specific bootloader module"
  import "${arch}/bootloader"
fi
