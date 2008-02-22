# $Id$

get_filename_from_uri() {
  local uri=$1

  basename "${1}"
}

get_path_from_uri() {
  local uri=$1

  echo "${uri}" | cut -d / -f 4-
}

get_protocol_from_uri() {
  local uri=$1

  echo "${uri}" | sed -e 's|://.\+$||'
}

fetch() {
  local uri=$1
  local localfile=$2

  local protocol=$(get_protocol_from_uri "${uri}")
  debug fetch "protocol is ${protocol}"
  if $(isafunc "fetch_${protocol}"); then
    fetch_${protocol} "${1}" "${2}"
    return $?
  else
    die "No fetcher for protocol ${protocol}"
  fi
}

fetch_quickstart() {
  local uri=$1
  local localfile=$2

  local realurl="http://${server_host}:${server_port}/$(get_path_from_uri "${uri}")"
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
  local uri=$1
  local localfile=$2

  debug fetch_http_https_ftp "Fetching URL ${uri} to ${2}"
  spawn "wget -O ${localfile} ${uri}"
  local wget_exitcode=$?
  debug fetch_http_https_ftp "exit code from wget was ${wget_exitcode}"
  return ${wget_exitcode}
}

fetch_file() {
  local uri=$1
  local localfile=$2

  uri=$(echo "${uri}" | sed -e 's|^file://||')
  debug fetch_file "Symlinking local file ${uri} to ${localfile}"
  ln -s "${uri}" "${localfile}"
}

fetch_tftp() {
  local uri=$1
  local localfile=$2

  uri=$(echo "${uri}" | sed -e 's|^tftp://||')
  host=$(echo "${uri}" | cut -d / -f 1)
  path=$(echo "${uri}" | cut -d / -f 2-)
  tftp -g -r "${path}" -l "${localfile}" "${host}" || die "could not fetch ${uri}"
}
