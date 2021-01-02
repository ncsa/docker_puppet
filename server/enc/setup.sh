#!/bin/bash

set -x

DEFAULT=~/pupperware
PDIR="${PUPPERWARE:-$DEFAULT}"
[[ -d "${PDIR}" ]] || {
    echo "Can't find pupperware dir at: $DEFAULT OR \$PUPPERWARE" 1>&2
    exit 1
}


REPO="${ENC_GIT_REPO:-https://github.com/ncsa/puppetserver-enc.git}"
BRANCH="${ENC_GIT_BRANCH:-master}"
git ls-remote --exit-code -h "${REPO}" "${BRANCH}" 2>/dev/null || {
  echo "FATAL: invalid repo '${REPO}' or branch '${BRANCH}'"
  exit 1
}


dokr_compose() {
  # workaround https://github.com/docker/compose/issues/6310
  # which says it's closed but still can't use --project-directory
  pushd "$PDIR" &>/dev/null
  docker-compose "$@"
  popd &>/dev/null
}


# make enc_adm runner script
enc_adm="$PDIR"/bin/enc_adm
[[ -f "$enc_adm" ]] || {
  /bin/cp -f "$PDIR"/bin/puppetserver "$enc_adm"
  sed -i -e 's|puppetserver|/etc/puppetlabs/enc/admin.py|' "$enc_adm"
}


# make puppetserver reload script
hup="$PDIR"/bin/hup
[[ -f "$hup" ]] || {
  /bin/cp -f "$PDIR"/bin/puppetserver "$hup"
  sed -i -e '/puppetserver/ d' "$hup"
  >>"$hup" echo "docker-compose exec puppet pkill -HUP -u puppet java"
  ln -sf hup "$PDIR"/bin/reload
}


# modify install.sh with git REPO and BRANCH
sed -i \
  -e "s|___ENC_GIT_REPO___|$REPO|" \
  -e "s|___ENC_GIT_BRANCH___|$BRANCH|" \
  "$PDIR"/server/enc/install.sh


# install enc (inside the container)
src="$PDIR"/server/enc/install.sh
tgt=/install_enc.sh
docker cp -L "$src" pupperware_puppet_1:"$tgt"
dokr_compose exec puppet bash -c "chown root:root $tgt"
dokr_compose exec puppet bash -c "$tgt 2>&1 | tee ${tgt}.log"

# Restart puppetserver
"$PDIR"/bin/hup
