# $Id$

GOOD='\033[32;01m'
WARN='\033[33;01m'
BAD='\033[31;01m'
HILITE='\033[36;01m'
BRACKET='\033[34;01m'
NORMAL='\033[0m'

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

  [ $quiet = 0 ] && echo -e " ${GOOD}*${NORMAL} ${msg}"
  log "${msg}"
}

error() {
  local msg=$1

  echo -e " ${BAD}*${NORMAL} ${msg}" >&2
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
  
  [ $quiet = 0 ] && echo -e " ${WARN}*${NORMAL} ${msg}" >&2
  log "Warning: ${msg}"
}

log() {
  local msg=$1

  if [ -n "${logfile}" -a -f "${logfile}" ]; then
    echo "$(date): ${msg}" >> ${logfile} 2>/dev/null
  fi
}
