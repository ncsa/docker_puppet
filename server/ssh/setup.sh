#!/bin/bash

set -x

DEFAULT=~/pupperware
PDIR="${PUPPERWARE:-$DEFAULT}"
[[ -d "${PDIR}" ]] || {
  echo "Can't find pupperware dir at: $DEFAULT OR \$PUPPERWARE" 1>&2
  exit 1
}
[[ -z "$DEPLOYKEY" ]] && {
  echo "ERROR - Missing DEPLOYKEY environment var" 1>&2
  exit 1
}
[[ -r "$DEPLOYKEY" ]] || {
  echo "ERROR - Can't read file '$DEPLOYKEY'" 1>&2
  exit 1
}


dokr_compose() {
  # workaround https://github.com/docker/compose/issues/6310
  # which says it's closed but still can't use --project-directory
  pushd "$PDIR" &>/dev/null
  docker-compose "$@"
  popd &>/dev/null
}

# Install ssh key into the container
dokr_compose exec puppet mkdir /etc/puppetlabs/r10k/ssh/
docker cp -L "$DEPLOYKEY" pupperware_puppet_1:/etc/puppetlabs/r10k/ssh/private-hiera-deploy-key
dokr_compose exec puppet chown root:root /etc/puppetlabs/r10k/ssh/private-hiera-deploy-key

# Install ssh packages in the container
docker cp -L "$PDIR"/server/ssh/install.sh pupperware_puppet_1:/install_ssh.sh
dokr_compose exec puppet /install_ssh.sh

# Install SSH config into the container
docker cp -L "$PDIR"/server/ssh/config pupperware_puppet_1:/etc/puppetlabs/r10k/ssh/config
dokr_compose exec puppet chown root:root /etc/puppetlabs/r10k/ssh/config
dokr_compose exec puppet rm -rf /root/.ssh
dokr_compose exec puppet ln -s /etc/puppetlabs/r10k/ssh /root/.ssh
