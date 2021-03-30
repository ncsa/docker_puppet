#!/bin/bash

set -x

TS=$(date +%s)
DEFAULT_PDIR=~/pupperware
PDIR="${PUPPERWARE:-$DEFAULT_PDIR}"
[[ -d "${PDIR}" ]] || {
  echo "Can't find pupperware dir at: $DEFAULT_PDIR OR \$PUPPERWARE" 1>&2
  exit 1
}


dokr_compose() {
  # workaround https://github.com/docker/compose/issues/6310
  # which says it's closed but still can't use --project-directory
  pushd "$PDIR" &>/dev/null
  docker-compose "$@"
  popd &>/dev/null
}


# update bash source files
# set proxy if needed
[[ -n "$https_proxy" ]] && {
  for src in "$PDIR"/server/bashrc/bashrc.d/*.sh "$PDIR"/server/bashrc/install.sh ; do
    sed -i \
      -e "s|___HTTP_PROXY___|$https_proxy|" \
      "$src"
  done
}

# Copy files locally
BASE="$HOME"/pup_bashrc
[[ -d "$BASE" ]] && rm -rf "$BASE"
mkdir -p "$BASE"
cp -a -t "$BASE" "$PDIR"/server/bashrc/.

# Run installer locally
installer="$BASE"/install.sh
chmod +x "$installer"
"$installer" 2>&1 | tee "${installer}".log

# copy files into the container
BASE=/root/pup_bashrc
docker cp -a "$PDIR"/server/bashrc pupperware_puppet_1:"$BASE"

# run the installer inside the container
installer="$BASE"/install.sh
dokr_compose exec puppet bash -c "chmod +x $installer"
dokr_compose exec puppet bash -c "$installer 2>&1 | tee ${installer}.log"
