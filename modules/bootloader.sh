# $Id$

map_device_to_grub_device() {
  local device=$1

  if [ ! -f "${chroot_dir}/boot/grub/device.map" ]; then
    debug map_device_to_grub_device "device.map doesn't exist...creating"
    spawn_chroot "echo quit | /sbin/grub --batch --no-floppy --device-map=/boot/grub/device.map" || die "could not create grub device map"
  fi
  local grub_device="$(grep "${device}\$" /boot/grub/device.map | awk '{ print $1; }')"
  if [ -z "${grub_device}" ]; then
    die "could not get grub device for ${device}"
  fi
  echo "${grub_device}"
}

get_kernel_and_initrd() {
  local kernels=""
  for kernel in ${chroot_dir}/boot/kernel-*; do
    if [ -e "$(echo ${kernel} | sed -e 's:/kernel-:/initrd-:')" ]; then
      local initrd="$(echo ${kernel} | sed -e 's:/kernel-:/initrd-:')"
    elif [ -e "$(echo ${kernel} | sed -e 's:/kernel-:/initramfs-:')" ]; then
      local initrd="$(echo ${kernel} | sed -e 's:/kernel-:/initrd-:')"
    fi
    if [ -n "${kernels}" ]; then
      kernels="${kernels} ${kernel}|${initrd}"
    else
      kernels="${kernel}|${initrd}"
    fi
  done
  echo "${kernels}"
}

