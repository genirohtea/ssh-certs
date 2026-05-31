#!/usr/bin/env bash
# https://betterdev.blog/minimal-safe-bash-script-template/
set -Eeuo pipefail

# script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

upsearch() {
  slashes=${PWD//[^\/]/}
  directory="$PWD"
  for ((n = ${#slashes}; n > 0; --n)); do
    test -e "$directory/$1" && break
    directory="$directory/.."
  done
  ansible_dir=$(python3 -c "import os;print(os.path.abspath('${directory}'))")
  echo "${ansible_dir}"
}

ansible_dir=$(upsearch ".ansible_root_signpost")
echo "Identified ansible root directory as ${ansible_dir}"

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-t <tags>] [-r] [-i] [-s <SHA>] -H <host>

This script runs the Ansible playbook for signing a host server for ssh certificates

Example: ./setup_host_server.sh --host host.example.com --site sitename --env prod

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-t, --tags      Specify Ansible tags to run specific tasks
-H, --host      Specify the host from the Ansible inventory to run the playbook on
-s, --site      The site the workstation will connect to
-a, --ansible_user      The user that ansible will use to connect to the server
-e, --env       The environment in the site to connect to
-d, --domain    The host domain to use for the signed certificate
-E, --expiry      The expiry timeframe of the generated certificate
-S, --use_ssh_pass Use password based ssh authentication
-p, --principals  The principals to sign the certificate for (in addition to the host)
EOF
  exit
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

tags=''
disable_key_check='false'
use_ssh_pass='false'
parse_params() {
  while :; do
    case "${1-}" in
      -h | --help) usage ;;
      -v | --verbose)
        set -x
        verbosity="-vvv"
        ;;
      -t | --tags)
        tags="${2-}"
        shift
        ;;
      -H | --host)
        host="${2-}"
        shift
        ;;
      -s | --site)
        site="${2-}"
        shift
        ;;
      -e | --env)
        env="${2-}"
        shift
        ;;
      -a | --ansible_user)
        ansible_user="${2-}"
        shift
        ;;
      -E | --expiry)
        expiry="${2-}"
        shift
        ;;
      -p | --principals)
        extra_principals="${2-}"
        shift
        ;;
      -d | --disable_key_check) disable_key_check='true' ;; # example flag
      -S | --use_ssh_pass) use_ssh_pass='true' ;;           # example flag
      -?*) die "Unknown option: $1" ;;
      *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
  [[ -z "${host-}" ]] && die "Missing required parameter: host"
  [[ -z "${site-}" ]] && die "Missing required parameter: site"
  [[ -z "${env-}" ]] && die "Missing required parameter: env"
  [[ -z "${use_ssh_pass-}" ]] && die "Missing required parameter: use_ssh_pass"
  if [[ -z "${expiry-}" ]]; then
    expiry="+395d"
  fi
  if [[ -z "${extra_principals-}" ]]; then
    principals="${host}"
  else
    principals="${extra_principals},${host}"
  fi
  if [[ -z "${ansible_user-}" ]]; then
    ansible_user="root"
  fi

  return 0
}

msg() {
  echo >&2 -e "${1-}"
}

parse_params "$@"

msg "Read parameters:"
msg "- arguments: ${args[*]-}"
msg "- environment: ${env-}"
msg "- host: ${host-}"
msg "- site: ${site-}"
msg "- ansible_user: ${ansible_user-}"
msg "- expiry: ${expiry-}"
msg "- principals: ${principals-}"
msg "- use_ssh_pass: ${use_ssh_pass-}"

if [[ "${use_ssh_pass}" != "true" ]]; then
  msg ""
  msg "NOTE: --use_ssh_pass is NOT set. If key-based SSH auth to ${host} as"
  msg "      ${ansible_user} has not been configured yet, re-run with"
  msg "      --use_ssh_pass to authenticate with a password instead."
  msg ""
fi

read -p "Please confirm arguments: " -n 1 -r
echo # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
  msg "User accepted arguments"
else
  die "User rejected arguments"
fi

msg "Running playbook on ${host}"

if [[ -n "${tags-}" ]]; then
  tags="--tags ${tags}"
fi

pushd "${ansible_dir}"

# If disable_key_check is supplied, turn off host key checking in ansible
# This handles the case where the certificate expires and we have configured the workstations to use strict host key checking
if [[ "${disable_key_check}" == "true" ]]; then
  export ANSIBLE_HOST_KEY_CHECKING=False
  echo "Disabled host key checking"
fi

if [[ "${use_ssh_pass}" == "true" ]]; then
  ssh_pass="--ask-pass"
fi

# Turn on verbosity to see the ansible run command
set -x

# shellcheck disable=SC2086
ansible-playbook setup_host_server.yml ${ssh_pass:-} ${verbosity:-} -u "${ansible_user}" ${tags} --extra-vars '{"site": "'"${site}"'", "env": "'"${env}"'", "expiry": "'"${expiry}"'", "principals": "'"${principals}"'", "identity": "'"${host}"'" }' -i "${host}",

# Turn off verbosity
set -x

popd
