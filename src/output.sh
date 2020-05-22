#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
# shellcheck disable=SC2154
set -eu

GOOD='\033[32;01m'
WARN='\033[33;01m'
BAD='\033[31;01m'
NORMAL='\033[0m'

logfile="/tmp/install.log"

debug() {
  func=$1
  msg=$2

  if [ "${debug}" = "1" ]; then
    echo "${func}(): ${msg}" >&2
    log "${func}(): ${msg}"
  fi
}

notify() {
  msg=$1

  if [ "${quiet}" = "0" ]; then
    printf " %s*%s %s" "${GOOD}" "${NORMAL}" "${msg}"
  fi

  log "${msg}"
}

error() {
  msg=$1

  printf " %s*%s %s" "${BAD}" "${NORMAL}" "${msg}" >&2
  log "Error: ${msg}"
}

die() {
  msg=$1

  error "${msg}"
  runstep failure_cleanup "Cleaning up after install failure"
  exit 1
}

warn() {
  msg=$1
  
  if [ "${quiet}" = "0" ]; then
    printf " %s*%s %s" "${WARN}" "${NORMAL}" "${msg}" >&2
  fi

  log "Warning: ${msg}"
}

log() {
  msg=$1

  if [ -n "${logfile}" ] && [ -f "${logfile}" ]; then
    echo "$(date): ${msg}" >> ${logfile} 2>/dev/null
  fi
}
