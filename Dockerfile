FROM ubuntu:16.04
MAINTAINER Jan Kunzmann <jan-docker@phobia.de>

RUN apt-get update && apt-get install -y \
                        sshguard \
                        iptables \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY script/entrypoint.sh /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
