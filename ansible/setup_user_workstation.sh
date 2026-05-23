#!/usr/bin/env bash
# https://betterdev.blog/minimal-safe-bash-script-template/
set -Eeuxo pipefail

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

This script runs the Ansible playbook for signing a host server for ssh certificates.

Example: ./setup_user_workstation.sh --host localhost --site sitename --env prod --user username --domain "*example.com" --add_root

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-t, --tags      Specify Ansible tags to run specific tasks
-H, --host      Specify the host from the Ansible inventory to run the playbook on
-s, --site      The site the workstation will connect to
-e, --env       The environment in the site to connect to
-u, --user      The user that will be used to connect to the servers
-d, --domain    The host domain regex that will be connected to
-E, --expiry      The expiry timeframe of the generated certificate
-S, --use_ssh_pass Use password based ssh authentication
-p, --principals  The principals to sign the certificate for (in addition to the user)
-r, --add_root    Adds root to the principals
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
add_root='false'
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
    -u | --user)
      user="${2-}"
      shift
      ;;
    -d | --domain)
      domain="${2-}"
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
    -r | --add_root) add_root='true' ;;         # example flag
    -S | --use_ssh_pass) use_ssh_pass='true' ;; # example flag
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
  [[ -z "${user-}" ]] && die "Missing required parameter: user"
  [[ -z "${domain-}" ]] && die "Missing required parameter: domain"
  [[ -z "${use_ssh_pass-}" ]] && die "Missing required parameter: use_ssh_pass"
  if [[ -z "${expiry-}" ]]; then
    expiry="+395d"
  fi
  if [[ -z "${extra_principals-}" ]]; then
    principals="${user}"
  else
    principals="${extra_principals},${user}"
  fi

  if [[ "${add_root}" == "true" ]]; then
    principals="${principals},root"
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
msg "- user: ${user-}"
msg "- domain: ${domain-}"
msg "- expiry: ${expiry-}"
msg "- principals: ${principals-}"

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

localhost_args=""
if [ "$host" == "localhost" ]; then
  localhost_args="--connection=local"
  echo "localhost_args is set to $localhost_args"
else
  echo "host is not localhost, no action taken."
fi

if [[ "${use_ssh_pass}" == "true" ]]; then
  ssh_pass="--ask-pass"
fi

pushd "${ansible_dir}"

# Turn on verbosity to see the ansible run command
set -x

# shellcheck disable=SC2086
ansible-playbook setup_user_workstation.yml ${ssh_pass:-} ${verbosity:-} ${tags} --extra-vars '{"site": "'"${site}"'", "env": "'"${env}"'", "user": "'"${user}"'", "expiry": "'"${expiry}"'", "principals": "'"${principals}"'", "domain": "'"${domain}"'" }' -i "${host}", ${localhost_args}

# Turn off verbosity
set -x

popd
