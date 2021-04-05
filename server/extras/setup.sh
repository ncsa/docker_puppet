#!/bin/bash

set -x

TS=$(date +%s)
DEFAULT=~/pupperware
PDIR="${PUPPERWARE:-$DEFAULT}"
[[ -d "${PDIR}" ]] || {
  echo "Can't find pupperware dir at: $DEFAULT OR \$PUPPERWARE" 1>&2
  exit 1
}


install_toml_rb() {
  "$PDIR/bin/puppetserver" gem install toml-rb
}


restart_puppetserver() {
  "$PDIR/bin/hup"
}


# Install bin files into pupperware/bin
install -vbCD --suffix="$TS" -t "$PDIR"/bin "$PDIR"/server/extras/bin/*

install_toml_rb

restart_puppetserver

