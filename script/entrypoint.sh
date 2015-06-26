#! /bin/sh

/bin/journalctl -D /app/journal/ --no-pager -q -f -n "${SSHGUARD_LOOKBACK:-50}" -t sshd \
  | /usr/sbin/sshguard -s "${SSHGUARD_FORGET_CRACKER:-1200}" -p "${SSHGUARD_UNBLOCK_AFTER:-420}"
  