# Setup Secure Access To A Private Git Server
These steps are needed to access a git repo on a server that is behind a firewall. The general process is:
- Setup an ssh key for access to the repo (on the git server)
- Create a persistent ssh tunnel for access to the git server

### SSH deploy key
Note:
- Must have a deploy key setup on the private git server.
- For production use, suggest a separate key per puppet master.
- These instructions assume an appropriate deploy key has already been created
  and installed on the private git server.
  - For additional help, see:
    - [GitHub](https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh)
    - [GitLab](https://docs.gitlab.com/ce/ssh/README.html)

---

### Identify SSH key
Setup session environment variables for the appropriate ssh deploy key.
Adjust the path here to point to the private ssh key to use.
- `export DEPLOYKEY=~/.ssh/r10k.deploy.key`
Commands below will use this session environment variable.

### Update SSH client config file
- `vim ~/pupperware/server/ssh/config`

### Install and configure ssh in the container
- `~/pupperware/server/ssh/setup.sh`

### Verify R10K has access to all repos defined in r10k.yaml
- `~/pupperware/bin/verify_repo_access`
