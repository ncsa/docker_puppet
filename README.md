# docker_puppet

### Requirements
Install each of the dependencies below:
- [docker](https://docs.docker.com/install/)
- [docker-compose](https://docs.docker.com/compose/install/)

# Install for Testing

### Install into $HOME/pupperware
- `curl -O https://github.com/ncsa/docker_puppet/blob/master/server/tools/reset.sh`
- `bash reset.sh`
- [Setup ENC](server/enc/README.md)
- [Setup R10K](server/r10k/README.md)

---

# Install for Production

For production servers, the `.env` file must be modified before starting up
puppetserver for the first time.

### Get pupperware
- `git clone https://github.com/puppetlabs/pupperware`
- `cd pupperware`

Note: All commands below are expected to be run from inside the pupperware
directory.

### Install NCSA customizations
- `export QS_REPO=https://github.com/ncsa/docker_puppet`
- `curl https://raw.githubusercontent.com/andylytical/quickstart/master/quickstart.sh | bash`

### Review .env settings
- `vim .env`

Note: For production, the values for `DOMAIN` and `DNS_ALT_NAMES` will need adjustments.

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
- Configure and Add nodes to the ENC
  - See: [ENC Common Actions](server/enc/README.md)

---

### Install R10K
- Install r10k in the container
  - `server/r10k/setup.sh`
- Configure and Run r10k
  - See: [R10K Common Actions](server/r10k/README.md)

---

### Install Extras
For production systems at NCSA, these are extra steps that are needed on the
puppetserver.

- `server/extras/setup.sh`

See also: server/extras/README.md

---

# Other Actions

- [Puppet agent in Vagrant VM](vagrant/README.md)
- [Non-interactive access to a private git server (behind a firewall)](server/ssh/README.md)
- [Extras](server/extras/README.md)
- Add pupperware/bin to PATH:
  - `server/bashrc/setup.sh`
