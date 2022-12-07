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

### ETCD新增节点

##例子
##修改etcd_install.sh内容
IP_LIST="10.100.2.64 10.100.2.65 10.100.2.66 10.100.2.58"

```shell
$ bash etcd_install.sh
$ sed -i "s/new/existing/g" /usr/local/etc/etcd/env
##运行etcd服务
$ etcdctl --endpoints=http://10.100.2.65:2379 member add  etcd_cluster-4 --peer-urls=http://10.100.2.58:2380
```



## helm_Hub

### monitor

:zap::修改value文件

#### grafana

##### 服务配置

```yaml
grafana.ini:
  paths:
    data: /var/lib/grafana/
    logs: /var/log/grafana
    plugins: /var/lib/grafana/plugins
    provisioning: /etc/grafana/provisioning
  analytics:
    check_for_updates: true
  log:
    mode: console
  grafana_net:
    url: https://grafana.net
  server:
    root_url: http://grafana.monitor.svc/grafana   ###添加prefixURL
    serve_from_sub_path: true
```

> serve_from_sub_path 允许添加prefix_url
>
> root_url 添加后缀 ‘/grafana’

调节**persistence** size

```yaml
persistence:
  type: pvc
  enabled: true   ####确认开启持久化
  accessModes:
    - ReadWriteOnce
  size: 300Gi
......
initChownData:
  ## If false, data ownership will not be reset at startup
  ## This allows the grafana-server to be run with an arbitrary user
  ##
  enabled: false   ####
```

#### prometheus

##### 添加prefixURL

```shell
server: 
 prefixURL: "/prometheus"
```

##### 服务配置

```yaml
  prometheus.yml:
    rule_files:
      - /etc/config/recording_rules.yml
      - /etc/config/alerting_rules.yml
    ## Below two files are DEPRECATED will be removed from this default values file
      - /etc/config/rules
      - /etc/config/alerts

      - job_name: kube-state-metrics
        static_configs:
          - targets:
            - prometheus-kube-state-metrics.monitor.svc:8080
```


