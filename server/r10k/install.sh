#!/bin/bash
 
PYTHON_PKGS=( python3 python3-venv )
OTHER_PKGS=( git )

# Setup Proxy
if [[ -n "___HTTP_PROXY___" ]] ; then
  export https_proxy="___HTTP_PROXY___"
fi
 
# Install dependencies
apt update \
&& apt install -y "${PYTHON_PKGS[@]}" "${OTHER_PKGS[@]}" \
&& apt clean \
&& rm -rf /var/lib/apt/lists/*

# Install custom R10K scripts
# the setup script will replace ___placeholders___ with useful values
export QS_REPO=___R10K_GIT_REPO___
export QS_GIT_BRANCH=___R10K_GIT_BRANCH___
export PUP_R10K_DIR=___PUP_R10K_DIR___
curl https://raw.githubusercontent.com/andylytical/quickstart/main/quickstart.sh | bash
