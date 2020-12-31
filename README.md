# docker_puppet

### Requirements
Install each of the dependencies below:
- [docker](https://docs.docker.com/install/)
- [docker-compose](https://docs.docker.com/compose/install/)

# Quickstart

---

### Get pupperware
- `git clone https://github.com/puppetlabs/pupperware`
- `cd pupperware`

Note: All commands below are expected to be run from inside the pupperware
directory.

### Install customizations from this repo
- `export QS_REPO=https://github.com/ncsa/docker_puppet`
- `curl https://raw.githubusercontent.com/andylytical/quickstart/master/quickstart.sh | bash`

### Review .env settings
- `vim .env`

### Start puppetserver
- `docker-compose up -d`
- Ensure all containers are started and healthy
  - `watch "docker-compose ps"`
    - Press Ctl-c to exit "watch" when all containers are healthy

Sample output when all containers are started and healthy:
```
       Name                       Command                  State               Ports
------------------------------------------------------------------------------------------------
pupperware_postgres_1   docker-entrypoint.sh postgres    Up (healthy)   5432/tcp
pupperware_puppet_1     dumb-init /docker-entrypoi ...   Up (healthy)   0.0.0.0:8140->8140/tcp
pupperware_puppetdb_1   dumb-init /docker-entrypoi ...   Up (healthy)   0.0.0.0:32779->8080/tcp,
                                                                        0.0.0.0:32778->8081/tcp
```

---

### Install ENC
- Install enc in the container
  - `server/enc/setup.sh`
- Verify enc setup
  - `bin/enc_adm -l`
  - `bin/enc_adm --help`

See also:
- [More ENC actions](docs/enc.md)
- https://github.com/ncsa/puppetserver-enc

---

### Install R10K
- Install r10k in the container
  - `server/r10k/setup.sh`
- Adjust r10k configuration
  - `docker cp -L pupperware_puppet_1:/etc/puppetlabs/r10k/r10k.yaml ~/pupperware/server/r10k/r10k.yaml`
  - `vim ~/pupperware/server/r10k/r10k.yaml`
  - `docker cp -L ~/pupperware/server/r10k/r10k.yaml pupperware_puppet_1:/etc/puppetlabs/r10k/`
- Verify r10k can access all the repos in it's config
  - `bin/verify_repo_access`
  - Resolve any errors before proceeding
    - See also:
      [Non-interactive access to a private git server (behind a firewall)](server/ssh/README.md)
- Run R10K
  - `bin/r10k`
  - No output means successful run. In the case of errors, view latest log file
    with:
    - `bin/r10k_log`

---

### Install Extras
For production systems at NCSA, these are extra steps that are needed on the
puppetserver.

- `server/extras/setup.sh`

See also: [server/extras/README.md](server/extras/README.md)

---

# Other Actions

- [Add nodes to the ENC](docs/enc.md)
- [Puppet agent in Vagrant VM](vagrant/README.md)
- [Non-interactive access to a private git server (behind a firewall)](server/ssh/README.md)
- [Extras](docs/extras.md)
- Add pupperware/bin to PATH:
  - `server/bashrc/setup.sh`
