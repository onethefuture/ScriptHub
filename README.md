# ScriptHub
System optimization and deployment documentation
## k8sCluster_install

:zap:: k8s_install脚本每个节点都要执行，根据情况调整`ETCD`集群IP

> `ETCD` 集群 IP 中间空格隔开

### 运行

```shell
$ chmod +x k8s_index.sh etcd_defrag.sh
$ ./k8s_index.sh
$ mv etcd_defrag.sh /usr/local/etc/etcd/
```

#### etcd清理垃圾定时任务

```shell
$ crontab -e
*/3 * * * * /usr/local/etcd/etcd_defrag.sh >> /usr/local/etcd/etcd_defrag.log
```

### ETCD集群验证

```shell
export ETCD_API=3
#查看集群健康信息
etcdctl --endpoints=http://192.168.100.10:2379,http://192.168.100.20:2379 endpoint health -w=table
#查看集群状态信息
etcdctl --endpoints=http://192.168.100.10:2379,http://192.168.100.20:2379 endpoint status -w=table
#查看集群成员信息
etcdctl --endpoints=http://192.168.100.10:2379 member list -w=table
#创建一个kv
etcdctl --endpoints=http://192.168.100.10:2379 put test "123"
#查询key
etcdctl --endpoints=http://192.168.100.10:2379 get test
```

