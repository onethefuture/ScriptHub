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
IP_LIST="192.168.100.10 192.168.100.20 192.168.100.30 192.168.100.40"

```shell
$ bash etcd_install.sh
$ sed -i "s/new/existing/g" /usr/local/etc/etcd/env
##运行etcd服务
$ etcdctl --endpoints=http://192.168.100.10:2379 member add  etcd_cluster-4 --peer-urls=http://192.168.100.40:2380
```

### K8S新增节点

#### control节点

```shell
##kubeadm工具
#创建token
$ kubeadm token create --ttl 0 --print-join-command
#创建新的证书密钥
$ kubeadm init phase upload-certs --upload-certs  (--config kubeadm-config.yaml)
```

> --ttl 0 永不过期
>
> --print-join-command  不仅仅打印令牌，而是打印使用令牌加入集群所需的完整 'kubeadm join' 参数 
>
> --config 指定自定义的配置文件，kubeadm默认join无需指定

`**证书密钥配合token一起使用**`

例子：

```shell
$  kubeadm join 192.168.100.10:6443 --token 3cdp6t.6tgur7pve8o7dbwp \
        --discovery-token-ca-cert-hash sha256:207d35b15595cc09c7a81f96b5f759f76cba17e03fcb52a685ff0e2710128cc3 \
        --control-plane --certificate-key 91a35d074a96f8bb3f37ac5b24fe275e41b578236707323dc154acaab3fe1178
```

#### work节点

```shell
##kubeadm工具
#创建token
$ kubeadm token create --ttl 0 --print-join-command
```

**直接使用打印出的token**

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


