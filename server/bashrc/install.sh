#!/bin/bash

set -x

TS=$(date +%s)
BASE=/root/pup_bashrc
BASHRC="$HOME"/.bashrc

# Install bashrc.d files locally
for src in "$BASE"/bashrc.d/*.sh ; do
  src_fn=$( basename "$src" )
  tgt="$HOME/.bashrc.d/$src_fn"
  install -vbCD --suffix="$TS" -T -m '0400' "$src" "$tgt"
done

# Update /root/.bashrc locally
grep -q '^# INCLUDE bashrc.d' "$BASHRC" || {
  cat "$BASE"/bashrc_snippet >> "$BASHRC"
}

# Do proxy setup
if [[ -n "___HTTP_PROXY___" ]] ; then
  PROXY="___HTTP_PROXY___"

  # Curl
  if [[ -f /root/.curlrc ]] && grep -q -F proxy /root/.curlrc ; then
    : #pass
  else
    echo "proxy = $PROXY" >> /root/.curlrc
  fi

  # Git
  git config --global http.proxy "$PROXY"

  # Apt
  if type apt &>/dev/null ; then
    grep -q -F 'Acquire::http::Proxy' /etc/apt/apt.conf || \
      echo "Acquire::http::Proxy \"http://$PROXY/\";" >> /etc/apt/apt.conf
  fi
fi
