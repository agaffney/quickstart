#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
set -eu

server_init() {
  if echo "${server}" | grep -q ":"; then
    server_host=$(echo "${server}" | cut -d : -f 1)
    server_port=$(echo "${server}" | cut -d : -f 2)
  else
    server_host="${server}"
  fi
  mac_address=$(get_mac_address)
  if [ -z "${server_port}" ]; then
    server_port=8899
  fi
}

server_send_request() {
  command=$1
  args=$2

  fetch "quickstart:///${command}?${args}" "/tmp/server_response"
  cat /tmp/server_response
}

server_get_profile() {
  profile_uri=$(server_send_request "get_profile_path" "mac=${mac_address}")
  if [ -z "${profile_uri}" ]; then
    warn "error in response from server...could not retrieve profile URI"
    return 1
  else
    debug server_get_profile "profile URI is ${profile_uri}"
    if ! fetch "${profile_uri}" "/tmp/quickstart_profile"; then
      error "could not fetch profile"
      exit 1
    fi
    notify "fetched profile from ${profile_uri}"
  fi
}

pre_failure_cleanup() {
  if [ -n "${server_host}" ]; then
    warn "We should probably tell the server something went wrong"
  fi
}
