#!/bin/sh
# An installer for Gentoo Linux written in POSIX shell
# SPDX-License-Identifier: GPL-2.0-only
set -eu

# Constants
VERSION="12.7.1"

# Options vars
debug=0
verbose=0
quiet=0
sanitycheck=0

import() {
  module=$1

  # shellcheck source=/dev/null
  . "modules/${module}.sh"
  debug import "imported module ${module}"
}

usage() {
  msg=$1

  if [ -n "${msg}" ]; then
    printf "%s\n" "${msg}"
  fi
  cat <<EOF
Usage:
  quickstart [-h|--help] [-d|--debug] [-v|--verbose] [-q|--quiet]
             [-s|--sanity-check] [--version] <profile>

Options:
  -h|--help            Show this message and quit
  -d|--debug           Output debugging messages
  -q|--quiet           Only output fatal error messages
  -v|--verbose         Be verbose (show external command output)
  -s|--sanity-check    Sanity check install profile and exit
  -c|--client <host>   Act as a client and connect to a quickstartd
  --version            Print version and exit

Arguments:
  profile              Path to an install profile
EOF
}

# Import modules
import output
import util
import spawn
import fetch
import portage
import bootloader
import partition
import step
import config
import stepcontrol
import server

# Parse args
while [ ${#} -gt 0 ]
do
  a=${1}
  shift
  case "${a}" in
    -h|--help)
      usage
      exit 0
      ;;
    -s|--sanity-check)
      sanitycheck=1
      ;;
    -d|--debug)
      # shellcheck disable=SC2034
      debug=1
      ;;
    -q|--quiet)
      if [ ${verbose} = 1 ]; then
        usage "The --quiet and --verbose options are mutually exclusive"
        exit 1
      fi
      quiet=1
      ;;
    -v|--verbose)
      if [ ${quiet} = 1 ]; then
        usage "The --quiet and --verbose options are mutually exclusive"
        exit 1
      fi
      verbose=1
      ;;
    -c|--client)
      server=${1}
      shift
      ;;
    --version)
      echo "Quickstart version ${VERSION}"
      exit 0
      ;;
    -*)
      usage "You have specified an invalid option: ${a}"
      exit 1
      ;;
    *)
      profile=$a
      ;;
  esac
done

if [ -n "${server}" ]; then
  server_init
  if server_get_profile; then
    profile="/tmp/quickstart_profile"
  fi
fi

if [ -z "${profile}" ]; then
  usage "You must specify a profile"
  exit 1
fi

if [ ! -f "${profile}" ]; then
  error "Specified profile does not exist!"
  exit 1
else
  # shellcheck source=/dev/null
  . "${profile}"
  if ! touch "${logfile:?}" 2>/dev/null; then
    error "Logfile is not writeable!"
    exit 1
  fi
  arch=$(get_arch)
  debug main "arch is ${arch}"
  [ -z "${arch}" ] && die "Could not determine arch!"
  runstep sanity_check_config "Sanity checking config"
  if [ "${sanitycheck}" = "1" ]; then
    debug main "Exiting due to --sanity-check"
    exit
  fi
fi


[ -z "${install_mode}" ] && install_mode="normal"

run_pre_install_script "Running pre-install script"

if [ "${install_mode}" != "chroot" ]; then 
  runstep partition "Partitioning"
fi

runstep setup_md_raid "Setting up RAID arrays"
runstep setup_lvm "Setting up LVM volumes"
runstep format_devices "Formatting devices"
runstep mount_local_partitions "Mounting local partitions"
runstep mount_network_shares "Mounting network shares"
runstep unpack_stage_tarball "Fetching and unpacking stage tarball"
runstep prepare_chroot "Preparing chroot"

if [ "${install_mode}" != "stage4" ]; then
  runstep install_portage_tree "Installing portage tree"
  runstep set_root_password "Setting root password"
  runstep set_timezone "Setting timezone"
  runstep setup_fstab "Setting up /etc/fstab"
  runstep build_kernel "Building kernel"
  runstep install_logging_daemon "Installing logging daemon"
  runstep install_cron_daemon "Installing cron daemon"
  runstep setup_network_post "Setting up post-install networking"
  runstep install_bootloader "Installing bootloader"
fi

if [ "${install_mode}" != "chroot" ]; then
  runstep configure_bootloader "Configuring bootloader"
fi

runstep install_extra_packages "Installing extra packages"
runstep add_and_remove_services "Adding and removing services"
runstep run_post_install_script "Running post-install script"
runstep finishing_cleanup "Cleaning up"

notify "Install complete!"

if [ "${reboot:=no}" = "yes" ]; then
  notify "Rebooting..."
  reboot
fi
