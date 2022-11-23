#!/usr/bin/env python
from __future__ import print_function
import socket
import sys
name = sys.argv[1]
ips = sys.argv[2:]
ip=socket.gethostbyname(socket.gethostname())
if ip not in ips:
        print('ip is nil',file=sys.stderr)
        exit(1)
idx = ips.index(ip) + 1
ETCD_INITIAL_CLUSTER=','.join(['%s-%i=http://%s:2380'%(name,ips.index(x)+1,x) for x in ips])
print('ETCD_DATA_DIR=/var/lib/etcd')
print('ETCD_NAME=%s-%i'%(name,idx))
print('ETCD_LISTEN_CLIENT_URLS=http://%s:2379'%ip)
print('ETCD_ADVERTISE_CLIENT_URLS=http://%s:2379'%ip)
print('ETCD_LISTEN_PEER_URLS=http://%s:2380'%ip)
print('ETCD_INITIAL_ADVERTISE_PEER_URLS=http://%s:2380'%ip)
print('ETCD_INITIAL_CLUSTER="%s"'%ETCD_INITIAL_CLUSTER)
print('ETCD_INITIAL_CLUSTER_TOKEN=%s'%name)
print('ETCD_INITIAL_CLUSTER_STATE=new')
print('ETCD_AUTO_COMPACTION_RETENTION=20')
print('ETCD_QUOTA_BACKEND_BYTES=8589934592')
print('ETCD_AUTO_COMPACTION_MODE=revision')
