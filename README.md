# docker-systemd-sshguard

A SSHGuard container suitable for systemd-based environment such as CoreOS.

It runs in a privileged container with the host's systemd journal directory being mounted and pipes the journal directly into sshguard.


## Usage

There are a couple of environment variables you can pass to the container:

* `IPTABLES_SETUP`, `IPTABLES_SETUP_IPV4` and `IPTABLES_SETUP_IPV6`: Set to "no" if you don't want the container to setup the required iptables rules in general, for IPv4 or IPv6, respectively (all default to "yes").
* `IPTABLE_BASE`: Name of the iptables filter rule in which the jump to the sshguard table will be appended or inserted (defaults to "INPUT").
* `IPTABLE_BASE_POS`: Position to insert the jump to the sshguard, or 0 to append (defaults to 0).
* `SSHGUARD_LOOKBACK`: How many lines of the journal should be parsed on initial startup (defaults to 50).
* `SSHGUARD_FORGET_CRACKER`: Specify after how many seconds sshguard will forget an attack (defaults to 1200).
* `SSHGUARD_UNBLOCK_AFTER`: Specify the baseline number of seconds an attacker will be blocked (defaults to 420).

Edit these variables into the unit file which fits best for your setup:

### CoreOS Cluster

```
fleetctl start sshguard-rkt.service
```

### CoreOS Single Instance

```
cp sshguard-rkt.service /etc/systemd/system/sshguard.service
systemctl daemon-reload
systemctl start sshguard.service
systemctl enable sshguard.service
```

### Generic Linux host using Docker

```
cp sshguard-docker.service /etc/systemd/system/sshguard.service
systemctl daemon-reload
systemctl start sshguard.service
systemctl enable sshguard.service
```

### Docker Compose

A proper `docker-compose.yml` is also provided.


## Credits

Copyright (c) 2016 Jan Kunzmann <jan-github@phobia.de>, see [LICENSE.md](LICENSE.md).

Heavily inspired by Nick Owens' [coreos-sshguard](https://github.com/mischief/coreos-sshguard)
