#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
set -eu

isafunc() {
  func=$1

  if LC_ALL=C type "${func}" 2>/dev/null | grep -q "function"; then
    return 0
  else
    return 1
  fi
}

runstep() {
  func=$1
  descr=$2

  skipfunc="skip_${func}"
  if [ "${skipfunc}" != "1" ]; then
    notify "${descr}"
    # shellcheck disable=SC2154
    if [ -n "${server}" ]; then
      server_send_request "update_status" "func=${func}&descr=$(echo "${descr}" | sed -e 's: :+:g')"
    fi
    if isafunc "pre_${func}"; then
      debug runstep "executing pre-hook for ${func}"
      "pre_${func}"
    fi
    ${func}
    if isafunc "post_${func}"; then
      debug runstep "executing post-hook for ${func}"
      "post_${func}"
    fi
  else
    debug runstep "skipping step ${func}"
  fi
}
