#!/bin/bash

set -x

BASE=$( dirname $0 )
TS=$(date +%s)

# Try to find pupperware install dir
[[ -z "$PUPPERWARE_HOME" ]] && INSTALL_DIR="$PUPPERWARE_HOME"
[[ -z "$INSTALL_DIR" ]] && INSTALL_DIR=~/pupperware
[[ -d "$INSTALL_DIR" ]] || {
  echo "FATAL: Can't find pupperware directory" >&2
  echo "Try setting PUPPERWARE_HOME environment variable" >&2
  exit 1
}


# Install from src to tgt
install_it() {
  set -x
  local _src="$1"
  local _tgt="$2"
  cp \
    --preserve=mode,timestamps \
    --recursive \
    "$_src" \
    "$_tgt"
}


# Copy dirs as-is
DIRLIST=( agent server vagrant )
for dir in "${DIRLIST[@]}"; do
  install_it "$BASE"/"$dir" "$INSTALL_DIR"/
done


# Copy files as-is
FILELIST=( $( ls "$BASE"/docker-compose*.yml ) )
for src in "${FILELIST[@]}"; do
  install_it "$src" "$INSTALL_DIR"/
done


# Copy files with different target name
declare -A FILEMAP
FILEMAP[env]=.env
for src in "${!FILEMAP[@]}"; do
  tgt="${FILEMAP[$src]}"
  install_it "$BASE"/"$src" "$INSTALL_DIR"/"$tgt"
done
