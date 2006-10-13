# $Id$

isafunc() {
  local func=$1

  if [ -n "$(type ${func} 2>/dev/null | grep "function")" ]; then
    return 0
  else
    return 1
  fi
}

runstep() {
  local func=$1
  local descr=$2

  notify "${descr}"
  if $(isafunc pre_${func}); then
    debug runstep "executing pre-hook for ${func}"
    pre_${func}
  fi
  ${func}
  if $(isafunc post_${func}); then
    debug runstep "executing post-hook for ${func}"
    post_${func}
  fi
}
