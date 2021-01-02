Puppet R10k

## First Time Setup

### Customize r10k.yaml
- `docker cp -L pupperware_puppet_1:/etc/puppetlabs/r10k/r10k.yaml ~/pupperware/server/r10k/r10k.yaml`
- `vim ~/pupperware/server/r10k/r10k.yaml`
- `docker cp -L ~/pupperware/server/r10k/r10k.yaml pupperware_puppet_1:/etc/puppetlabs/r10k/`

### Verify r10k can access all the repos in it's config
- `~/pupperware/bin/verify_repo_access`
- Resolve any errors before proceeding
  - See also:
    [Non-interactive access to a private git server (behind a firewall)](server/ssh/README.md)


## Common Actions

### Run R10K
- `~/pupperware/bin/r10k`
- No output means successful run. In the case of errors, view latest log file
  with:
  - `~/pupperware/bin/r10k_log`


## Less Common Actions

### Install a different R10K repo and/or branch
- `export R10K_GIT_REPO=https://github.com/ncsa/puppetserver-r10k`
- `export R10K_GIT_BRANCH=my/custom/branch`
- `~/pupperware/server/r10k/setup.sh`
