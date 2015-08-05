## This Dockerfile is meant to aid in the building and debugging patroni whilst developing on your local machine
## It has all the necessary components to play/debug with a single node appliance, running etcd
FROM ubuntu:14.04
MAINTAINER Feike Steenbergen <feike.steenbergen@zalando.de>

# We need curl
RUN apt-get update -y && apt-get install curl -y

# Add PGDG repositories
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RUN apt-get update -y
RUN apt-get upgrade -y

ENV PGVERSION 9.4
RUN apt-get install python python-psycopg2 python-yaml python-requests python-boto postgresql-${PGVERSION} python-dnspython python-pip -y
RUN pip install zake

ENV PATH /usr/lib/postgresql/${PGVERSION}/bin:$PATH

RUN mkdir -p /patroni/helpers
ADD patroni.py /patroni/patroni.py
ADD helpers /patroni/helpers
ADD postgres0.yml /patroni/

ENV ETCDVERSION 2.0.12
RUN curl -L https://github.com/coreos/etcd/releases/download/v${ETCDVERSION}/etcd-v${ETCDVERSION}-linux-amd64.tar.gz | tar xz -C /bin --strip=1 --wildcards --no-anchored etcd etcdctl

## Setting up a simple script that will serve as an entrypoint
RUN mkdir /data/ && touch /var/log/etcd.log /var/log/etcd.err && chown postgres:postgres /var/log/etcd.*
RUN chown postgres:postgres -R /patroni/ /data/
ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
USER postgres