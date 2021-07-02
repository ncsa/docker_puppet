# docker_puppet

### Requirements
Install each of the dependencies below:
- [docker](https://docs.docker.com/install/)
- [docker-compose](https://docs.docker.com/compose/install/)

# Install

### Preparation (Production use-case only)
> Installation for production use means puppet agent will run on separate nodes
> that will communicate with the puppet server over the network (as opposed to
> a testing install where-in all traffic will remain on the localhost.)
> For more information, see the "Provisioning" section of
> https://github.com/puppetlabs/pupperware
> 
> If using as a test install on a local laptop or workstation, this step should
> be skipped.

- Set environment variables
  - `export DNS_ALT_NAMES=short_hostname,fully_qualified_hostname,IP_Address,IP_Address`
    - Can be skipped and a suggestion will be offered.
    - Set this ahead of time to allow unattended installation.
    - For a test install (all traffic will remain on the localhost), set this
      to DNS_ALT_NAMES=internal
  - `export https_proxy=proxy.host.name:1234`
    - Only if the host requires a proxy to reach the public internet.

### Installation
- `curl -O https://raw.githubusercontent.com/ncsa/docker_puppet/main/server/tools/reset.sh`
- `bash reset.sh`

### Configuration

- [Configure ENC](server/enc/README.md)
- [Configure R10K](server/r10k/README.md)

---

# Other Actions

- [Puppet agent in Vagrant VM](vagrant/README.md)
- [Non-interactive access to a private git server (behind a firewall)](server/ssh/README.md)
