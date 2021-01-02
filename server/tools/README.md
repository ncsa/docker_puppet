Puppet in Docker - Useful tools

## Reset
- `export QS_REPO=https://github.com/ncsa/docker_puppet`
- Optional
  - `export QS_GIT_BRANCH=alternate/branch/for/docker_puppet`
  - `export ENC_GIT_BRANCH=different/enc/branch`
  - `export R10K_GIT_BRANCH=alternate/r10k/branch`
  - `export PUPPERWARE=/alternate/pupperware/install/dir`
- `cd; curl -O 
  https://raw.githubusercontent.com/ncsa/docker_puppet/${QS_GIT_BRANCH:-master}/server/tools/reset.sh`
- `bash reset.sh`
