#!/bin/bash

mkdir /var/lib/etcd
chown nobody /var/lib/etcd
python env.py $@ >/usr/local/etc/etcd/env
