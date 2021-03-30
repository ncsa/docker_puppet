#!/bin/bash

# SET THESE AS APPROPRIATE FOR TESTING
# export QS_REPO=https://github.com/ncsa/docker_puppet
# export QS_GIT_BRANCH=...
# export ENC_GIT_BRANCH=...
# export R10K_GIT_BRANCH=...

set -x

TS=$(date +%s)
QUICKSTART=https://raw.githubusercontent.com/andylytical/quickstart/master/quickstart.sh

PDIR="${PUPPERWARE:-$HOME/pupperware}"
echo "Pupperware install dir: '$PDIR'"


# use default repo if QS_REPO is not set
[[ -z "$QS_REPO" ]] && export QS_REPO=https://github.com/ncsa/docker_puppet
echo "QS_REPO=$QS_REPO"


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
  type git || {
    echo "ERROR 'git' not found"
    exit 1
  }
}


assert_docker() {
  systemctl show --property ActiveState docker | grep -q 'ActiveState=active' || {
    echo "ERROR: Docker is not running."
    exit 1
  }
}


_get_env_proxy() {
  local _proxy=""
  # check for env var http_proxy
  _proxy=$(echo ${http_proxy})
  [[ -z "$_proxy" ]] && \
  _proxy=$(echo ${https_proxy})
  echo "$_proxy"
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
  _proxy=$( docker info | awk -v IGNORECASE=1 '/PROXY/ {print $NF}' )
  echo "$_proxy"
}


_set_docker_proxy() {
  local _proxy="$1"
  local _fn _docker_proxy
  if [[ -n "$_proxy" ]] ; then
    _docker_proxy=$( _get_docker_proxy )
    if [[ "$_docker_proxy" != "$_proxy" ]] ; then
      _fn=/etc/systemd/system/docker.service.d/http-proxy.conf
      mkdir -p $( dirname "$_fn" )
      >"$_fn" cat <<ENDHERE
[Service]
Environment="HTTP_PROXY=http://${HTTP_PROXY}"
Environment="HTTPS_PROXY=http://${HTTP_PROXY}"
Environment="NO_PROXY=puppet,puppetdb,localhost,127.0.0.1,*.ncsa.illinois.edu"
ENDHERE
      systemctl daemon-reload
      systemctl show --property Environment docker #check to make sure your proxy shows up here
      systemctl restart docker
      systemctl enable docker
    fi
  fi
}


_set_git_proxy() {
  local _proxy="$1"
  local _git_proxy
  if [[ -n "$_proxy" ]] ; then
    _git_proxy=$( git config --get http.proxy )
    if [[ "$_git_proxy" != "$_proxy" ]] ; then
      git config --global http.proxy "$_proxy"
    fi
  fi
}


_set_yum_proxy() {
  local _proxy="$1"
  if [[ -n "$_proxy" ]] ; then
    # add to dnf
    if type dnf &>/dev/null ; then
      _fn=/etc/dnf/dnf.conf
      mkdir -p $(dirname "$_fn")
      touch "$_fn"
      grep -q -i proxy "$_fn" || \
        echo "proxy=http://${_proxy}/" >> $_fn
    fi
    # add to yum
    if type yum &>/dev/null ; then
      _fn=/etc/yum.conf
      mkdir -p $(dirname "$_fn")
      touch "$_fn"
      grep -q -i proxy "$_fn" || \
        echo "proxy=http://${_proxy}/" >> $_fn
    fi
  fi
}


configure_proxy() {
  # check for proxy environment variable
  HTTP_PROXY=$( _get_env_proxy )
  # OR check for proxy in curl config
  [[ -z "$HTTP_PROXY" ]] && HTTP_PROXY=$( _get_curl_proxy )
  # if proxy found, setup host services to use it
  if [[ -n "$HTTP_PROXY" ]] ; then
    _set_curl_proxy "$HTTP_PROXY"
    _set_docker_proxy "$HTTP_PROXY"
    _set_git_proxy "$HTTP_PROXY"
    _set_yum_proxy "$HTTP_PROXY"
  fi
}


assert_git
assert_docker

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
all_services_up || { 
  echo 'SERVICES NOT STARTED' >&2
  exit 1
}

# Continue setup steps
export COMPOSE_INTERACTIVE_NO_CLI=1
"$PDIR"/server/bashrc/setup.sh \
&& "$PDIR"/server/extras/setup.sh \
&& "$PDIR"/server/enc/setup.sh \
&& "$PDIR"/server/r10k/setup.sh
unset COMPOSE_INTERACTIVE_NO_CLI
