#!/bin/bash
 
PYTHON_PKGS=( python3 python3-venv )

# Setup Proxy
if [[ -n "___HTTP_PROXY___" ]] ; then
  export https_proxy="___HTTP_PROXY___"
fi
 
# Install dependencies
apt update \
&& apt install -y "${PYTHON_PKGS[@]}" "${OTHER_PKGS[@]}" \
&& apt clean \
&& rm -rf /var/lib/apt/lists/*

 
# Setup custom ENC
# the setup script will replace ___placeholders___ with useful values
export QS_REPO=___ENC_GIT_REPO___
export QS_GIT_BRANCH=___ENC_GIT_BRANCH___
curl https://raw.githubusercontent.com/andylytical/quickstart/main/quickstart.sh | bash
