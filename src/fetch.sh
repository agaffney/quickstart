#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
set -eu

get_filename_from_uri() {
  uri=$1

  basename "${1}"
}

get_path_from_uri() {
  uri=$1

  echo "${uri}" | cut -d / -f 4-
}

get_protocol_from_uri() {
  uri=$1

  echo "${uri}" | sed -e 's|://.\+$||'
}

fetch() {
  uri=$1
  localfile=$2

  protocol=$(get_protocol_from_uri "${uri}")
  debug fetch "protocol is ${protocol}"
  if isafunc "fetch_${protocol}"; then
    "fetch_${protocol}" "${1}" "${2}"
    return $?
  else
    die "No fetcher for protocol ${protocol}"
  fi
}

fetch_quickstart() {
  uri=$1
  localfile=$2

  realurl="http://${server_host}:${server_port}/$(get_path_from_uri "${uri}")"
  fetch_http_https_ftp "${realurl}" "${localfile}"
}

fetch_http() {
  debug fetch_http "calling fetch_http_https_ftp() to do real work"
  fetch_http_https_ftp "$@"
}

fetch_https() {
  debug fetch_http "calling fetch_http_https_ftp() to do real work"
  fetch_http_https_ftp "$@"
}

fetch_ftp() {
  debug fetch_http "calling fetch_http_https_ftp() to do real work"
  fetch_http_https_ftp "$@"
}

fetch_http_https_ftp() {
  uri=$1
  localfile=$2

  debug fetch_http_https_ftp "Fetching URL ${uri} to ${2}"
  spawn "wget -O ${localfile} ${uri}"
  wget_exitcode=$?
  debug fetch_http_https_ftp "exit code from wget was ${wget_exitcode}"
  return ${wget_exitcode}
}

fetch_file() {
  uri=$1
  localfile=$2

  uri=$(echo "${uri}" | sed -e 's|^file://||')
  debug fetch_file "Symlinking file ${uri} to ${localfile}"
  ln -s "${uri}" "${localfile}"
}

fetch_tftp() {
  uri=$1
  localfile=$2

  uri=$(echo "${uri}" | sed -e 's|^tftp://||')
  host=$(echo "${uri}" | cut -d / -f 1)
  path=$(echo "${uri}" | cut -d / -f 2-)
  tftp -g -r "${path}" -l "${localfile}" "${host}" || die "could not fetch ${uri}"
}
