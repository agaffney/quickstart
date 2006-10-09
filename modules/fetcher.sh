# $Id$

get_filename_from_uri() {
  uri=$1

  basename "${1}"
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
  if $(isafunc "fetch_${protocol}"); then
    fetch_${protocol} "${1}" "${2}"
    return $?
  else
    die "No fetcher for protocol ${protocol}"
  fi
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

  debug fetch_http "Fetching URL ${uri} to ${2}"
  spawn "wget -O ${localfile} ${uri}" || die "could not fetch ${uri}"
  debug fetch_http "exit code from wget was $?"
}

fetch_file() {
  uri=$1
  localfile=$2

  uri=$(echo "${uri}" | sed -e 's|^file://||')
  debug fetch_file "Copying local file ${uri} to ${localfile}"
  cp "${uri}" "${localfile}"
}
