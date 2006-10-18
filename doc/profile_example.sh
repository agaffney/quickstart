# $Id$

stage_uri http://192.168.0.12/stage3-i686-2006.1.tar.bz2
tree_type snapshot http://192.168.0.12/portage-20061005.tar.bz2
rootpw password
bootloader grub

part hda 1 83 100M
part hda 2 82 512M
part hda 3 83 +

format /dev/hda1 ext2
format /dev/hda2 swap
format /dev/hda3 ext3

mountfs /dev/hda1 ext2 /boot
mountfs /dev/hda2 swap
mountfs /dev/hda3 ext3 / noatime

#netmount 192.168.0.12:/usr/portage nfs /usr/portage ro

post_install_portage_tree() {
  cat > ${chroot_dir}/etc/make.conf <<EOF
CHOST="i686-pc-linux-gnu"
CFLAGS="-O2 -march=athlon-xp -pipe"
CXXFLAGS="\${CFLAGS}"
USE="-X -gtk -gnome -kde -qt"
EOF

  echo "portdbapi.auxdbmodule = cache.metadata_overlay.database" > ${chroot_dir}/etc/portage/modules
}
