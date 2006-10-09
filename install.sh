#!/bin/ash
# $Id$

# Constants
VERSION=foon

# Options vars
pretend=0
debug=0
verbose=0
quiet=0
sanitycheck=0

# Includes
source modules/output.sh
source modules/misc.sh
source modules/spawn.sh
source modules/fetcher.sh
source modules/portage.sh
source modules/install_steps.sh
source modules/config.sh
source modules/stepcontrol.sh

usage() {
  msg=$1

  if [ -n "${msg}" ]; then
    echo -e "${msg}\n"
  fi
  cat <<EOF
Usage:
  install.sh [-h|--help] [-p|--pretend] [-d|--debug] [-v|--verbose] [--version]
             [-q|--quiet] [-s|--sanity-check]

Options:
  -h|--help            Show this message and quit
  -p|--pretend         Don't actually perform any actions
  -d|--debug           Output debugging messages
  -q|--quiet           Only output fatal error messages
  -v|--verbose         Be verbose (show external command output)
  -s|--sanity-check    Sanity check install profile and exit
  --version            Print version and exit
EOF
}

# Parse args
params=${#}
while [ ${#} -gt 0 ]
do
  a=${1}
  shift
  case "${a}" in
    -h|--help)
      usage
      exit 0
      ;;
    -p|--pretend)
      pretend=1
      ;;
    -s|--sanity-check)
      sanitycheck=1
      ;;
    -d|--debug)
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
    --version)
      echo "install.sh version ${VERSION}"
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

if [ -z "${profile}" ]; then
  usage "You must specify a profile"
  exit 1
fi
if [ ! -f "${profile}" ]; then
  die "Specified profile does not exist!"
else
  source "${profile}"
  runstep sanity_check_config "Sanity checking config"
  if [ "${sanitycheck}" = "1" ]; then
    debug main "Exiting due to --sanity-check"
    exit
  fi
fi

arch=$(get_arch)
debug main "arch is ${arch}"
[ -z "${arch}" ] && die "Could not determine arch!"

[ -z "${mode}" ] && mode="normal"

run_pre_install_script "Running pre-install script"

if [ "${mode}" != "chroot" ]; then 
  partition "Partitioning"
fi

runstep setup_md_raid "Setting up RAID arrays"
runstep format_devices "Formatting devices"
runstep mount_local_partitions "Mounting local partitions"
runstep mount_network_shares "Mounting network shares"
runstep unpack_stage_tarball "Fetching and unpacking stage tarball"
runstep prepare_chroot "Preparing chroot"
#run_pre_chroot_script

if [ "${mode}" != "stage4" ]; then
  runstep install_portage_tree "Installing portage tree"
  runstep set_root_password "Setting root password"
  runstep set_timezone "Setting timezone"
  runstep build_kernel "Building kernel"
  runstep install_logging_daemon "Installing logging daemon"
  runstep install_cron_daemon "Installing cron daemon"
  runstep setup_network_post "Setting up post-install networking"
  runstep install_bootloader "Installing bootloader"
fi

if [ "${mode}" != "chroot" ]; then
  runstep configure_bootloader "Configuring bootloader"
fi

runstep install_extra_packages "Installing extra packages"
runstep run_post_install_script "Running post-install script"
runstep finishing_cleanup "Cleaning up"

notify "Install complete!"

if [ "${reboot}" = "yes" ]; then
  notify "Rebooting..."
  reboot
fi
