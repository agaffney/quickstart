# $Id$

emerge() {
  pkgs=$1

  debug emerge "pkgs is '${pkgs}'"
  spawn_chroot "emerge ${emerge_opts} ${pkgs}"
}
