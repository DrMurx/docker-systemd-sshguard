# docker-systemd-sshguard

An [SSHGuard](http://www.sshguard.net) container suitable for systemd-based environment such as [CoreOS](http://coreos.com).

It is supposed to run in a privileged container with the host's systemd journal directory being mounted, and pipes the journal directly into sshguard.


## Usage

There are a couple of environment variables you can pass to the container:

* `IPTABLES_SETUP`, `IPTABLES_SETUP_IPV4` and `IPTABLES_SETUP_IPV6`: Set to "no" if you don't want the container to setup the required iptables rules in general, for IPv4 or IPv6, respectively (all default to "yes").
* `IPTABLES_TEARDOWN`: Set to "no" if you want to keep the sshguard iptables after shutting down the container (defaults to "yes").
* `IPTABLE_BASE`: Name of the iptables filter rule in which the jump to the sshguard table will be appended or inserted (defaults to "INPUT").
* `IPTABLE_BASE_POS`: Position in the iptables filter rule where to insert the jump to the sshguard table, or 0 to append (defaults to 0).
* `JOURNALD_START_AT`: Starting point in the journal, can be any absolute or relative timestamp `strtotime` is able to parse (defaults to "2 hours ago").
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


## TODO

* Get rid of the bloated ubuntu base image. Compiling journalctl/systemd on alpine is a challenge.
* Upcoming sshguard version supports `ipset` backend to avoid cluttering the iptables.


## Credits

Copyright (c) 2016 Jan Kunzmann <jan-github@phobia.de>, see [LICENSE.md](LICENSE.md).

Heavily inspired by Nick Owens' [coreos-sshguard](https://github.com/mischief/coreos-sshguard)
