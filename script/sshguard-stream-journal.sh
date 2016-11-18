#! /bin/bash

# Set to "no" if you don't want the container to setup the required iptables rules in general, for IPv4 or IPv6, respectively
IPTABLES_SETUP="${IPTABLES_SETUP:-yes}"
IPTABLES_SETUP_IPV4="${IPTABLES_SETUP_IPV4:-yes}"
IPTABLES_SETUP_IPV6="${IPTABLES_SETUP_IPV6:-yes}"

# Set to "no" if you want to keep the sshguard iptables after shutting down the container
IPTABLES_TEARDOWN="${IPTABLES_TEARDOWN:-yes}"

# Name of the iptables filter rule in which the jump to the sshguard table will be appended or inserted
IPTABLE_BASE="${IPTABLE_BASE:-INPUT}"

# Position to insert the jump to the sshguard, or 0 to append
IPTABLE_BASE_POS="${IPTABLE_BASE_POS:-0}"

# How many lines of the journal should be parsed on initial startup
SSHGUARD_LOOKBACK="${SSHGUARD_LOOKBACK:-50}"

# Specify after how many seconds sshguard will forget an attack
SSHGUARD_FORGET_CRACKER="${SSHGUARD_FORGET_CRACKER:-1200}"

# Specify the baseline number of seconds an attacker will be blocked
SSHGUARD_UNBLOCK_AFTER="${SSHGUARD_UNBLOCK_AFTER:-420}"


function setupIptables {
  if [[ "${IPTABLE_BASE_POS}" -gt 0 ]]; then
    iptCommand="-I ${IPTABLE_BASE} ${IPTABLE_BASE_POS}"
  else
    iptCommand="-A ${IPTABLE_BASE}"
  fi
  
  if [[ "${IPTABLES_SETUP_IPV4}" != "no" ]]; then
    /sbin/iptables -N sshguard 2> /dev/null
    /sbin/iptables -F sshguard
    if ! /sbin/iptables -C "${IPTABLE_BASE}" -j sshguard 2> /dev/null; then
      /sbin/iptables ${iptCommand} -j sshguard
    fi
  fi

  if [[ "${IPTABLES_SETUP_IPV6}" != "no" ]]; then
    /sbin/ip6tables -N sshguard 2> /dev/null
    /sbin/ip6tables -F sshguard
    if ! /sbin/ip6tables -C "${IPTABLE_BASE}" -j sshguard 2> /dev/null; then
      /sbin/ip6tables ${iptCommand} -j sshguard
    fi
  fi
}


function teardownIptables {
  if [[ "${IPTABLES_SETUP_IPV4}" != "no" ]]; then
    /sbin/iptables -D "${IPTABLE_BASE}" -j sshguard
    /sbin/iptables -F sshguard
    /sbin/iptables -X sshguard
  fi

  if [[ "${IPTABLES_SETUP_IPV6}" != "no" ]]; then
    /sbin/ip6tables -D "${IPTABLE_BASE}" -j sshguard
    /sbin/ip6tables -F sshguard
    /sbin/ip6tables -X sshguard
  fi
}


if [[ "${IPTABLES_SETUP}" != "no" ]]; then
  setupIptables

  if [[ "${IPTABLES_TEARDOWN}" != "no" ]]; then
    # Trap to clean the IPTables; sleep is required to allow sshguard to release the lock on xtables
    trap 'sleep 1; teardownIptables' EXIT
  fi
fi

# Trap to kill the background processes if this script is signalled to terminate
trap 'kill $(jobs -p);' SIGHUP SIGINT SIGTERM

/bin/journalctl -D /app/journal/ --no-pager -q -f -n "${SSHGUARD_LOOKBACK}" -t sshd \
  | /usr/sbin/sshguard -s "${SSHGUARD_FORGET_CRACKER}" -p "${SSHGUARD_UNBLOCK_AFTER}" &

wait
