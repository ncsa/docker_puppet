Puppet in Docker - Useful tools

## Reset - Advanced Usage
- In addition to setting the required environment variables from [README](/README.md),
  the following additional settings are also valid:
  - `export QS_REPO=https://github.com/ncsa/docker_puppet`
  - `export QS_GIT_BRANCH=alternate/branch/for/docker_puppet`
  - `export ENC_GIT_BRANCH=different/enc/branch`
  - `export R10K_GIT_BRANCH=alternate/r10k/branch`
  - `export PUPPERWARE_HOME=/alternate/pupperware/install/dir`
- Follow the usual instructions to retrieve a copy of the reset.sh script and
  run it locally.

## Debugging inside the container
The container environment is designed to be minimal for efficiency. To get
additional cmdline tools installed inside the container use the debugging.sh
script.
- `docker cp -L pupperware_puppet_1:/debugging.sh
  ~/pupperware/server/tools/debugging.sh`
- `docker exec pupperware_puppet_1 /debugging.sh`

Now run bash in the container and continue debugging:
- `docker exec pupperware_puppet_1 bash`
