#!/bin/bash

set -x

DEFAULT=~/pupperware
PDIR="${PUPPERWARE:-$DEFAULT}"
[[ -d "${PDIR}" ]] || {
    echo "Can't find pupperware dir at: $DEFAULT OR \$PUPPERWARE" 1>&2
    exit 1
}

INSTALL_DIR="${PUP_R10K_DIR:-/etc/puppetlabs/r10k}"
REPO="${R10K_GIT_REPO:-https://github.com/ncsa/puppetserver-r10k}"
BRANCH="${R10K_GIT_BRANCH:-master}"
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


# r10k runner script (outside the container)
tgt="$PDIR"/bin/r10k
[[ -f "$tgt" ]] || {
  /bin/cp -f "$PDIR"/bin/puppetserver $tgt
  sed -i -e '1c\#!/bin/bash' $tgt
  sed -i -e '/puppetserver/ d' $tgt
  >>$tgt echo 'echo "R10K Start $(date)"'
  >>$tgt echo "docker-compose exec puppet /r10k \"\$@\""
  >>$tgt echo 'echo'
  >>$tgt echo 'echo "R10K End $(date)"'
  >>$tgt echo 'echo "ELAPSED: $SECONDS (seconds)"'
}


# Custom log viewer script (outside the container)
tgt="$PDIR"/bin/r10k_log
[[ -f "$tgt" ]] || {
  /bin/cp -f "$PDIR"/bin/puppetserver $tgt
  sed -i -e '/puppetserver/ d' $tgt
  >>$tgt cat <<ENDHERE
tmpfn=\$(mktemp)
>\$tmpfn docker-compose exec puppet bash -c 'cat /var/log/r10k/\$(ls /var/log/r10k | tail -1)'
less \$tmpfn
rm \$tmpfn
ENDHERE
}


# custom script to verify r10k repo access (outside the container)
tgt="$PDIR"/bin/verify_repo_access
[[ -f "$tgt" ]] || {
  /bin/cp -f "$PDIR"/bin/puppetserver "$tgt"
  sed -i -e 's/puppetserver/\/verify_repo_access.sh/' "$tgt"
}

# custom script to verify r10k repo access (inside the container)
docker cp -L "$PDIR"/server/r10k/verify_repo_access.sh pupperware_puppet_1:/verify_repo_access.sh
dokr_compose exec puppet chmod +x /verify_repo_access.sh


# symlink custom r10k runner (inside the container)
dokr_compose exec puppet bash -c "ln -sf $INSTALL_DIR/r10k.sh /r10k"


# modify install.sh with git REPO and BRANCH
sed -i \
  -e "s|___R10K_GIT_REPO___|$REPO|" \
  -e "s|___R10K_GIT_BRANCH___|$BRANCH|" \
  -e "s|___PUP_R10K_DIR___|$INSTALL_DIR|" \
  "$PDIR"/server/r10k/install.sh
# set proxy if needed
[[ -n "$https_proxy" ]] && {
  sed -i \
    -e "s|___HTTP_PROXY___|$https_proxy|" \
    "$PDIR"/server/r10k/install.sh
}

# install r10k inside the container
src="$PDIR"/server/r10k/install.sh
tgt=/install_r10k.sh
docker cp -L "$src" pupperware_puppet_1:"$tgt"
dokr_compose exec puppet bash -c "chown root:root '$tgt'"
dokr_compose exec puppet bash -c "$tgt 2>&1 | tee ${tgt}.log"
