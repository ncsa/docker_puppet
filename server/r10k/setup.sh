#!/bin/bash

set -x

DEFAULT=~/pupperware
cd "${PUPPERWARE:-$DEFAULT}" || {
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


# r10k runner script (outside the container)
tgt=bin/r10k
/bin/cp -f bin/puppetserver $tgt
sed -i -e '/puppetserver/ d' $tgt
>>$tgt echo 'echo "R10K Start $(date)"'
>>$tgt echo "docker-compose exec puppet /r10k \"\$@\""
>>$tgt echo 'echo'
>>$tgt echo 'echo "R10K End $(date)"'
>>$tgt echo 'echo "ELAPSED: $SECONDS (seconds)"'


# Custom log viewer script (outside the container)
tgt=bin/r10k_log
/bin/cp -f bin/puppetserver $tgt
sed -i -e '/puppetserver/ d' $tgt
>>$tgt cat <<ENDHERE
tmpfn=\$(mktemp)
>\$tmpfn docker-compose exec puppet bash -c 'cat /var/log/r10k/\$(ls /var/log/r10k | tail -1)'
less \$tmpfn
rm \$tmpfn
ENDHERE


# custom script to verify r10k repo access (outside the container)
docker cp -L server/r10k/verify_repo_access.sh pupperware_puppet_1:/verify_repo_access.sh
docker-compose exec puppet chmod +x /verify_repo_access.sh
/bin/cp -f bin/puppetserver bin/verify_repo_access
sed -i -e 's/puppetserver/\/verify_repo_access.sh/' bin/verify_repo_access


# symlink custom r10k runner (inside the container)
docker-compose exec puppet bash -c "ln -sf $INSTALL_DIR/r10k.sh /r10k"


# modify install.sh with git REPO and BRANCH
sed -i \
  -e "s|___R10K_GIT_REPO___|$REPO|" \
  -e "s|___R10K_GIT_BRANCH___|$BRANCH|" \
  -e "s|___PUP_R10K_DIR___|$INSTALL_DIR|" \
  server/r10k/install.sh


# install r10k inside the container
src=server/r10k/install.sh
tgt=/install_r10k.sh
docker cp -L "$src" pupperware_puppet_1:"$tgt"
docker-compose exec puppet bash -c "chown root:root '$tgt'"
docker-compose exec puppet bash -c "$tgt 2>&1 | tee ${tgt}.log"
