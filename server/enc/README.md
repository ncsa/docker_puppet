Puppet ENC

## First Time Setup

### Customize tables.yaml
- `~/pupperware/bin/cp_from_puppet /etc/puppetlabs/enc/tables.yaml ~/pupperware/server/enc/tables.yaml`
- `vim ~/pupperware/server/enc/tables.yaml`
- `~/pupperware/bin/cp_to_puppet ~/pupperware/server/enc/tables.yaml /etc/puppetlabs/enc/`

### Initialize enc database
- `~/pupperware/bin/enc_adm --init`

Note: This will wipe out any existing data.
Backups are automatically stored on every enc_adm action, so old data can be
restored. See config.ini for backup location (default=`/var/backups/puppet-enc`).

### Verify enc setup
- `~/pupperware/bin/enc_adm -l`
- `~/pupperware/bin/enc_adm --help`


## Common Actions

### Help
- `~/pupperware/bin/enc_adm -h`
- `~/pupperware/bin/enc_adm --help`

### Listing nodes
- `~/pupperware/bin/enc_adm -l`
- `~/pupperware/bin/enc_adm -l fqdn1 fqdn2`
- `~/pupperware/bin/enc_adm -l patrn` #will show all nodes that match 'patrn' anywhere in
  the nodename

### Adding nodes
- Add a node using default values in tables.yaml
  ```shell
  ~/pupperware/bin/enc_adm --add --fqdn FQDN
  ```
- Add a node changing a specific parameter
  ```shell
  ~/pupperware/bin/enc_adm --add --environment env1 --site testsite --fqdn FQDN
  ```

### Change environment for a node (to match a branch in the puppet control repo)
- `~/pupperware/bin/enc_adm --topic git_branch_name FQDN`
- `~/pupperware/bin/enc_adm --ch --environment git_branch_name FQDN`

### See the actual yaml response to the puppetserver ENC request
```shell
~/pupperware/bin/enc_adm FQDN
```


## Less Common Actions

### Add a new column to an existing ENC table
- `enc_adm -l | awk 'NR==1{num=split($0,hdrs);next;} NR==2{next} {printf "enc_adm --add";for (i=1;i<num;i++)printf " --%s %s",hdrs[i],$i;print ""}' >/root/enc_bkup`
- `~/pupperware/bin/copy_from_puppet /etc/puppetlabs/enc/tables.yaml ~/pupperware/server/enc/tables.yaml`
- `vim ~/pupperware/server/enc/tables.yaml`
- `~/pupperware/bin/copy_to_puppet ~/pupperware/server/enc/tables.yaml /etc/puppetlabs/enc/`
- `bash enc_bkup`


### Customize enc repo and/or branch
- `export ENC_GIT_REPO=https://github.com/ncsa/puppetserver-enc`
- `export ENC_GIT_BRANCH=my/custom/branch`
- `~/pupperware/server/enc/setup.sh`
