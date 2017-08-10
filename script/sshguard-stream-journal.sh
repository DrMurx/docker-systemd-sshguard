#! /bin/bash

# Set to "no" if you don't want the container to setup the required iptables rules in general, for IPv4 or IPv6, respectively
IPTABLES_SETUP="${IPTABLES_SETUP:-yes}"
IPTABLES_SETUP_IPV4="${IPTABLES_SETUP_IPV4:-yes}"
IPTABLES_SETUP_IPV6="${IPTABLES_SETUP_IPV6:-yes}"

# Set to "no" if you want to keep the sshguard iptables after shutting down the container
IPTABLES_TEARDOWN="${IPTABLES_TEARDOWN:-yes}"

# A comma separated list of iptables filter chains in the jump to the sshguard table will be appended (default) or inserted.
# Add an optional `:n` to each chain name to insert at the nth position.
IPTABLES_HOOK="${IPTABLES_HOOK:-INPUT:1}"

# Starting point in the journal, can be any absolute or relative timestamp `strtotime` is able to parse.
JOURNALD_START_AT="${JOURNALD_START_AT:-2 hours ago}"

# Specify after how many seconds sshguard will forget an attack
SSHGUARD_FORGET_CRACKER="${SSHGUARD_FORGET_CRACKER:-1200}"

# Specify the baseline number of seconds an attacker will be blocked
SSHGUARD_UNBLOCK_AFTER="${SSHGUARD_UNBLOCK_AFTER:-420}"


function setupAllIptables {
  if [[ "${IPTABLES_SETUP_IPV4}" != "no" ]]; then
    setupIptables /sbin/iptables
  fi
  if [[ "${IPTABLES_SETUP_IPV6}" != "no" ]]; then
    setupIptables /sbin/ip6tables
  fi
}

function setupIptables {
  IPTABLES=${1}

  declare -a hooks
  hooks=($(echo ${IPTABLES_HOOK} | sed -e 's/,/ /g'))

  ${IPTABLES} -N sshguard 2> /dev/null
  ${IPTABLES} -F sshguard
  for hook in ${hooks[*]}; do
    pos=${hook#*:}
    hook=${hook%:*}
    if [[ "${pos:-0}" -gt 0 ]]; then
      iptCommand="-I ${hook} ${pos}"
    else
      iptCommand="-A ${hook}"
    fi
    if ! ${IPTABLES} -C "${hook}" -j sshguard 2> /dev/null; then
      ${IPTABLES} ${iptCommand} -j sshguard
    fi
  done
}


function teardownAllIptables {
  if [[ "${IPTABLES_SETUP_IPV4}" != "no" ]]; then
    teardownIptables /sbin/iptables
  fi
  if [[ "${IPTABLES_SETUP_IPV6}" != "no" ]]; then
    teardownIptables /sbin/ip6tables
  fi
}

function teardownIptables {
  IPTABLES=${1}

  declare -a hooks
  hooks=($(echo ${IPTABLES_HOOK} | sed -e 's/,/ /g'))

  for hook in ${hooks[*]}; do
    hook=${hook%:*}
    ${IPTABLES} -D "${hook}" -j sshguard
  done
  ${IPTABLES} -F sshguard
  ${IPTABLES} -X sshguard
}


if [[ "${IPTABLES_SETUP}" != "no" ]]; then
  setupAllIptables

  if [[ "${IPTABLES_TEARDOWN}" != "no" ]]; then
    # Trap to clean the IPTables; sleep is required to allow sshguard to release the lock on xtables
    trap 'sleep 1; teardownAllIptables' EXIT
  fi
fi

# Trap to kill the background processes if this script is signalled to terminate
trap 'kill $(jobs -p);' SIGHUP SIGINT SIGTERM

/bin/journalctl -D /app/journal/ --no-pager -q -f -S "${JOURNALD_START_AT}" -t sshd \
  | /usr/sbin/sshguard -s "${SSHGUARD_FORGET_CRACKER}" -p "${SSHGUARD_UNBLOCK_AFTER}" &

wait
