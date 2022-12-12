#!/bin/bash
rev=$(ETCDCTL_API=3 etcdctl endpoint status --write-out="json" | egrep -o '"revision":[0-9]*' | egrep -o '[0-9]*')

echo $rev

# 压缩所有旧版本
ETCDCTL_API=3 etcdctl compact $rev
# 去碎片化
ETCDCTL_API=3 etcdctl defrag
# 取消警报
ETCDCTL_API=3 etcdctl alarm disarm
# 测试通过
ETCDCTL_API=3 etcdctl put key0 1234