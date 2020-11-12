#!/bin/bash

set -x

DEFAULT=~/pupperware
cd "${PUPPERWARE:-$DEFAULT}" || {
    echo "Can't find pupperware dir at: $DEFAULT OR \$PUPPERWARE" 1>&2
    exit 1
}


REPO="${ENC_GIT_REPO:-https://github.com/ncsa/puppetserver-enc.git}"
BRANCH="${ENC_GIT_BRANCH:-master}"
git ls-remote --exit-code -h "${REPO}" "${BRANCH}" 2>/dev/null || {
  echo "FATAL: invalid repo '${REPO}' or branch '${BRANCH}'"
  exit 1
}


# make enc_adm runner script
enc_adm=bin/enc_adm
[[ -f "$enc_adm" ]] || {
  /bin/cp -f bin/puppetserver "$enc_adm"
  sed -i -e 's|puppetserver|/etc/puppetlabs/enc/admin.py|' "$enc_adm"
}


# make puppetserver reload script
hup=bin/hup
[[ -f "$hup" ]] || {
  /bin/cp -f bin/puppetserver "$hup"
  sed -i -e '/puppetserver/ d' "$hup"
  >>"$hup" echo "docker-compose exec puppet pkill -HUP -u puppet java"
  ln -sf hup bin/reload
}


# modify install.sh with git REPO and BRANCH
sed -i \
  -e "s|___ENC_GIT_REPO___|$REPO|" \
  -e "s|___ENC_GIT_BRANCH___|$BRANCH|" \
  server/enc/install.sh


# install enc (inside the container)
src=server/enc/install.sh
tgt=/install_enc.sh
docker cp -L "$src" pupperware_puppet_1:"$tgt"
docker-compose exec puppet bash -c "chown root:root '$tgt'"
docker-compose exec puppet bash -c "$tgt 2>&1 | tee ${tgt}.log"
bin/hup


# initialize enc database
bin/enc_adm --init
