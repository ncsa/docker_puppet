#!/bin/bash

# SET THESE AS APPROPRIATE FOR TESTING
# export QS_REPO=https://github.com/ncsa/docker_puppet
# export QS_GIT_BRANCH=...
# export ENC_GIT_BRANCH=...
# export R10K_GIT_BRANCH=...

set -x

TS=$(date +%s)
QUICKSTART=https://raw.githubusercontent.com/andylytical/quickstart/main/quickstart.sh

# use default repo if QS_REPO is not set
[[ -z "$QS_REPO" ]] && export QS_REPO=https://github.com/ncsa/docker_puppet
echo "QS_REPO=$QS_REPO"


log() {
  echo "INFO: $*"
}

warn() {
  echo "WARN: $*"
}

error() {
  echo "ERROR: $*" 1>&2
}

croak() {
  echo "FATAL ERROR: $*" 1>&2
  echo "Exiting"
  exit 99
}

ask_yes_no() {
  local rv=1
  local msg="Is this ok?"
  [[ -n "$1" ]] && msg="$1"
  echo "$msg"
  select yn in "Yes" "No"; do
    case $yn in
      Yes) rv=0;;
      No ) rv=1;;
    esac
    break
  done
  return $rv
}


get_dns_alt_names() {
  local _parts=()
  _parts+=( $(hostname) )
  _parts+=( $(hostname -f) )
  _parts+=( $( ip -o -4 a s \
    | awk '$2~/(^lo$|^docker)/{next}{split($4,parts,"/");printf "%s\n",parts[1]}' ) )
  ( IFS=','; cat <<< "${_parts[*]}" )
}


dokr_compose() {
  # workaround https://github.com/docker/compose/issues/6310
  # which says it's closed but still can't use --project-directory
  pushd "$PDIR" &>/dev/null
  docker-compose "$@"
  popd &>/dev/null
}

all_services_up() {
  local _svc_count=$(dokr_compose ps --services | wc -l)
  local _ok_count=$(dokr_compose ps -a | tail -n+3 | grep -F 'Up (healthy)'| wc -l)
  [[ $_ok_count -eq $_svc_count ]]
}


rm_existing_pupperware() {
  [[ -d "$PDIR" ]] || return 0
  dokr_compose stop \
  && docker system prune -af --volumes \
  && mv "$PDIR" "${PDIR}.$TS"
}


assert_git() {
  type git || croak "'git' not found"
}


assert_docker() {
  systemctl show --property ActiveState docker | grep -q 'ActiveState=active' || \
    croak "Docker is not running."
}


assert_docker_compose() {
  type docker-compose || croak "'docker-compose' not found"
  local _path=$( type docker-compose | tail -1 | awk '{print $NF}' )
  [[ -x "$_path" ]] || croak "'docker-compose' is not executable"
}


assert_env_var() {
  local _name="$1"
  local _default="$2"
  local _val="${!_name}"
  if [[ -z "$_val" ]] ; then
    warn "Missing value for '$_name'."
    if ask_yes_no "Use default value '${_name}=${_default}'?" ; then
      eval "export ${_name}=\"${_default}\""
    else
      croak "Cannot proceed. Try setting environment variable '$_name'."
    fi
  fi
}


_get_env_proxy() {
  local _proxy=""
  # check for env var http_proxy
  _proxy=$(echo ${http_proxy})
  [[ -z "$_proxy" ]] && \
  _proxy=$(echo ${https_proxy})
  echo "$_proxy"
}


_set_env_proxy() {
  eval "export http_proxy=$1"
}


_get_curl_proxy() {
  local _proxy=""
  # check for curl proxy
  [[ -f ~/.curlrc ]] && \
    _proxy=$( awk '/proxy/ {print $NF}; {next}' ~/.curlrc )
  echo "$_proxy"
}


_set_curl_proxy() {
  local _proxy="$1"
  local _curl_proxy=$( _get_curl_proxy )
  if [[ "$_curl_proxy" != "$_proxy" ]] ; then
    echo "proxy = $_proxy" >> ~/.curlrc
  fi
}


_get_docker_proxy() {
  local _proxy=""
  # check for docker proxy
  _proxy=$( docker info | awk -v IGNORECASE=1 '/HTTP PROXY/ {print $NF}' )
  echo "$_proxy"
}


_set_docker_proxy() {
  local _proxy="$1"
  local _fn _docker_proxy
  if [[ -n "$_proxy" ]] ; then
    _docker_proxy=$( _get_docker_proxy )
    if [[ "$_docker_proxy" != "http://$_proxy" ]] ; then
      _fn=/etc/systemd/system/docker.service.d/http-proxy.conf
      mkdir -p $( dirname "$_fn" )
      >"$_fn" cat <<ENDHERE
[Service]
Environment="http_proxy=http://${HTTP_PROXY}"
Environment="https_proxy=http://${HTTP_PROXY}"
Environment="no_proxy=puppet,puppetdb,localhost,127.0.0.1,*.ncsa.illinois.edu"
ENDHERE
      systemctl daemon-reload
      systemctl restart docker
      systemctl enable docker
      docker info | awk -v IGNORECASE=1 '/PROXY/ {print $NF}'
    fi
  fi
}


_set_git_proxy() {
  local _proxy="$1"
  git config --global http.proxy "$_proxy"
}


_set_yum_proxy() {
  local _proxy="$1"
  yum-config-manager --setopt="proxy=http://${_proxy}/" --save
}


configure_proxy() {
  # check for proxy environment variable
  HTTP_PROXY=$( _get_env_proxy )
  # OR check for proxy in curl config
  [[ -z "$HTTP_PROXY" ]] && HTTP_PROXY=$( _get_curl_proxy )
  # if proxy found, setup host services to use it
  if [[ -n "$HTTP_PROXY" ]] ; then
    _set_env_proxy "$HTTP_PROXY"
    _set_curl_proxy "$HTTP_PROXY"
    _set_docker_proxy "$HTTP_PROXY"
    _set_git_proxy "$HTTP_PROXY"
    _set_yum_proxy "$HTTP_PROXY"
  fi
}


dump_var() {
  echo "${1}=${!1}"
}


assert_git
assert_docker
assert_docker_compose
assert_env_var PUPPERWARE_HOME "$HOME/pupperware"
assert_env_var DNS_ALT_NAMES "$( get_dns_alt_names )"
assert_env_var DOMAIN "ncsa.illinois.edu"
PDIR="$PUPPERWARE_HOME"
for v in PUPPERWARE_HOME DNS_ALT_NAMES DOMAIN PDIR ; do
  dump_var "$v"
done
croak "FORCED EXIT"

configure_proxy

pushd ~ \
&& rm_existing_pupperware \
&& git clone https://github.com/puppetlabs/pupperware "$PDIR" \
&& curl $QUICKSTART | bash \
&& dokr_compose up -d
popd

echo "Waiting for services to start ..."
for i in $(seq 2); do
  sleep 30
  all_services_up && break
done
all_services_up || croak 'SERVICES NOT STARTED'

# Continue setup steps
export COMPOSE_INTERACTIVE_NO_CLI=1
"$PDIR"/server/bashrc/setup.sh \
&& "$PDIR"/server/enc/setup.sh \
&& "$PDIR"/server/r10k/setup.sh \
&& "$PDIR"/server/extras/setup.sh
unset COMPOSE_INTERACTIVE_NO_CLI
