# $Id$

GOOD=$'\e[32;01m'
WARN=$'\e[33;01m'
BAD=$'\e[31;01m'
HILITE=$'\e[36;01m'
BRACKET=$'\e[34;01m'
NORMAL=$'\e[0m'

logfile=/tmp/install.log

debug() {
  local func=$1
  local msg=$2

  if [ "${debug}" = "1" ]; then
    echo "${func}(): ${msg}" >&2
    log "${func}(): ${msg}"
  fi
}

notify() {
  local msg=$1

  [ $quiet = 0 ] && echo " ${GOOD}*${NORMAL} ${msg}"
  log "${msg}"
}

error() {
  local msg=$1

  echo " ${BAD}*${NORMAL} ${msg}" >&2
  log "Error: ${msg}"
}

die() {
  local msg=$1

  error "${msg}"
  runstep failure_cleanup "Cleaning up after install failure"
  exit 1
}

warn() {
  local msg=$1
  
  [ $quiet = 0 ] && echo " ${WARN}*${NORMAL} ${msg}" >&2
  log "Warning: ${msg}"
}

log() {
  local msg=$1

  if [ -n "${logfile}" ]; then
    echo "$(date): ${msg}" >> ${logfile} 2>/dev/null
  fi
}
