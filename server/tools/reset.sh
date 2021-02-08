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


assert_git
assert_docker

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
"$PDIR"/server/enc/setup.sh \
&& "$PDIR"/server/r10k/setup.sh \
&& "$PDIR"/server/extras/setup.sh
unset COMPOSE_INTERACTIVE_NO_CLI
