### 部署

#### 下载，测试版本暂定3.3.10

```
wget https://github.com/etcd-io/etcd/releases/download/v3.3.10/etcd-v3.3.10-linux-amd64.tar.gz

解压到/data/etcd目录
mkdir -p /data/etcd/
tar zxvf etcd-v3.3.10-linux-amd64.tar.gz -C /data/etcd/

或者/usr/local/etcd/ 目录
mkdir -p /usr/local/etcd/
tar zxvf etcd-v3.3.10-linux-amd64.tar.gz -C /usr/local/etcd/
```

#### 修改/etc/profile

```
vim /etc/profile
添加
export ETCD_HOME=/data/etcd/etcd-v3.3.10-linux-amd64
export PATH=$ETCD_HOME:$PATH
# 是否启用v3客户端
#export ETCDCTL_API=3
```

或者/usr/local/etcd/ 目录 export ETCD\_HOME=/usr/local/etcd/etcd-v3.3.10-linux-amd64 export PATH=$ETCD\_HOME:$PATH

```
让其生效
source /etc/profile
```

#### 编写system unit

```
测试节点：
10.100.173.206
10.100.173.207
10.100.173.208

一个集群至少三个节点。
现在默认设置是206为master。
如果部署到其他服务器上，建议直接替换同时替换三个配置文件的ip即可。

system unit文件：
/usr/lib/systemd/system/etcd.service
```

\
三个节点的配置文件分别如下：

```
206 配置：
[Unit]
Description=etcd server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/data/etcd/
EnvironmentFile=-/data/etcd/etcd.conf
ExecStart=/data/etcd/etcd-v3.3.10-linux-amd64/etcd --name master --initial-advertise-peer-urls http://10.100.173.206:2380 --listen-peer-urls http://10.100.173.206:2380 --listen-client-urls http://10.100.173.206:2379,http://127.0.0.1:2379 --advertise-client-urls http://10.100.173.206:2379 --initial-cluster-token etcd-cluster-1 --initial-cluster master=http://10.100.173.206:2380,node1=http://10.100.173.207:2380,node2=http://10.100.173.208:2380 --initial-cluster-state new --data-dir=/data/etcd

Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

207配置：
[Unit]
Description=etcd server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/data/etcd/
EnvironmentFile=-/data/etcd/etcd.conf
ExecStart=/data/etcd/etcd-v3.3.10-linux-amd64/etcd --name node1 --initial-advertise-peer-urls http://10.100.173.207:2380 --listen-peer-urls http://10.100.173.207:2380 --listen-client-urls http://10.100.173.207:2379,http://127.0.0.1:2379 --advertise-client-urls http://10.100.173.207:2379 --initial-cluster-token etcd-cluster-1 --initial-cluster master=http://10.100.173.206:2380,node1=http://10.100.173.207:2380,node2=http://10.100.173.208:2380 --initial-cluster-state new --data-dir=/data/etcd

Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

208配置：
[Unit]
Description=etcd server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/data/etcd/
EnvironmentFile=-/data/etcd/etcd.conf
ExecStart=/data/etcd/etcd-v3.3.10-linux-amd64/etcd --name node2 --initial-advertise-peer-urls http://10.100.173.208:2380 --listen-peer-urls http://10.100.173.208:2380 --listen-client-urls http://10.100.173.208:2379,http://127.0.0.1:2379 --advertise-client-urls http://10.100.173.208:2379 --initial-cluster-token etcd-cluster-1 --initial-cluster master=http://10.100.173.206:2380,node1=http://10.100.173.207:2380,node2=http://10.100.173.208:2380 --initial-cluster-state new --data-dir=/data/etcd

Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
    
```

#### 服务启动

```
systemctl daemon-reload
systemctl enable etcd
systemctl restart etcd
systemctl status etcd
```

#### 常用命令

```
查看集群成员
etcdctl member list

检查集群监控状态
etcdctl cluster-health
或者使用http的方式也可以
curl http://10.100.173.206:2379/health

写
etcdctl set name wadeson    

读
etcdctl get name

ssl:
etcdctl --ca-file /data/etcd/bin/ca.pem get name
```

### 管理工具调研

```
etcd-browser
etcd-console
etcd-viewer
ETCD Manager
etcdkeeper
```

### 阿里云测试环境

```
47.110.127.250
内网ip
10.111.21.26
目录：
/data/users/cj16020/etcd/etcd-v3.3.10-linux-amd64

加到path中：
vim ~/.bashrc

export ETCD_HOME=/data/users/cj16020/etcd/etcd-v3.3.10-linux-amd64
export PATH=$ETCD_HOME:$PATH

source ~/.bashrc

启动命令：
etcd --name 'gsetcd-01' --data-dir '/data/users/cj16020/etcd/etcd-v3.3.10-linux-amd64/data' --listen-client-urls 'http://0.0.0.0:2379' --advertise-client-urls 'http://0.0.0.0:2379' --listen-peer-urls 'http://0.0.0.0:2380' --initial-advertise-peer-urls 'http://0.0.0.0:2380'

使用start.sh nohup方式启动：
nohup etcd --name 'gsetcd-01' --data-dir '/data/users/cj16020/etcd/etcd-v3.3.10-linux-amd64/data' --listen-client-urls 'http://0.0.0.0:2379' --advertise-client-urls 'http://0.0.0.0:2379' --listen-peer-urls 'http://0.0.0.0:2380' --initial-advertise-peer-urls 'http://0.0.0.0:2380' > etcd.log 2>&1 &

```

### 线上部署到/usr/local

```
etcd 对磁盘io和网络io要求比较高。
为了更好的性能最好使用ssd硬盘。
现在的很多服务器，ssd做系统盘，机械磁盘做/data
所以将etcd部署到/usr/local下

以汾湖第二集群为例：
vim /usr/lib/systemd/system/etcd.service

153 配置:
[Unit]
Description=etcd server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/usr/local/etcd/
EnvironmentFile=-/usr/local/etcd/etcd.conf
ExecStart=/usr/local/etcd/etcd-v3.3.10-linux-amd64/etcd --name master --initial-advertise-peer-urls http://10.189.6.153:2380 --listen-peer-urls http://10.189.6.153:2380 --listen-client-urls http://10.189.6.153:2379,http://127.0.0.1:2379 --advertise-client-urls http://10.189.6.153:2379 --initial-cluster-token etcd-cluster-1 --initial-cluster master=http://10.189.6.153:2380,node1=http://10.189.6.154:2380,node2=http://10.189.6.155:2380 --initial-cluster-state new --data-dir=/usr/local/etcd --snapshot-count 2000000000

Restart=on-failure
RestartSec=5
LimitNOFILE=655360

[Install]
WantedBy=multi-user.target


154 配置:
[Unit]
Description=etcd server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/usr/local/etcd/
EnvironmentFile=-/usr/local/etcd/etcd.conf
ExecStart=/usr/local/etcd/etcd-v3.3.10-linux-amd64/etcd --name node1 --initial-advertise-peer-urls http://10.189.6.154:2380 --listen-peer-urls http://10.189.6.154:2380 --listen-client-urls http://10.189.6.154:2379,http://127.0.0.1:2379 --advertise-client-urls http://10.189.6.154:2379 --initial-cluster-token etcd-cluster-1 --initial-cluster master=http://10.189.6.153:2380,node1=http://10.189.6.154:2380,node2=http://10.189.6.155:2380 --initial-cluster-state new --data-dir=/usr/local/etcd --snapshot-count 2000000000

Restart=on-failure
RestartSec=5
LimitNOFILE=655360

[Install]
WantedBy=multi-user.target

155 配置:
[Unit]
Description=etcd server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/usr/local/etcd/
EnvironmentFile=-/usr/local/etcd/etcd.conf
ExecStart=/usr/local/etcd/etcd-v3.3.10-linux-amd64/etcd --name node2 --initial-advertise-peer-urls http://10.189.6.155:2380 --listen-peer-urls http://10.189.6.155:2380 --listen-client-urls http://10.189.6.155:2379,http://127.0.0.1:2379 --advertise-client-urls http://10.189.6.155:2379 --initial-cluster-token etcd-cluster-1 --initial-cluster master=http://10.189.6.153:2380,node1=http://10.189.6.154:2380,node2=http://10.189.6.155:2380 --initial-cluster-state new --data-dir=/usr/local/etcd --snapshot-count 2000000000

Restart=on-failure
RestartSec=5
LimitNOFILE=655360

[Install]
WantedBy=multi-user.target





经过优化会更新的配置（以此为准）：
153配置：
[Unit]
Description=etcd server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/usr/local/etcd/
EnvironmentFile=-/usr/local/etcd/etcd.conf
ExecStart=/usr/local/etcd/etcd-v3.3.10-linux-amd64/etcd --name master --initial-advertise-peer-urls http://10.189.6.153:2380 --listen-peer-urls http://10.189.6.153:2380 --listen-client-urls http://10.189.6.153:2379,http://127.0.0.1:2379 --advertise-client-urls http://10.189.6.153:2379 --initial-cluster-token etcd-cluster-1 --initial-cluster master=http://10.189.6.153:2380,node1=http://10.189.6.154:2380,node2=http://10.189.6.155:2380 --initial-cluster-state new --data-dir=/usr/local/etcd --max-wals 2 --max-snapshots 2 --snapshot-count 2000000000 --quota-backend-bytes 8589934592 --auto-compaction-retention 1

Restart=on-failure
RestartSec=5
LimitNOFILE=655360

[Install]
WantedBy=multi-user.target

154配置：
[Unit]
Description=etcd server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/usr/local/etcd/
EnvironmentFile=-/usr/local/etcd/etcd.conf
ExecStart=/usr/local/etcd/etcd-v3.3.10-linux-amd64/etcd --name node1 --initial-advertise-peer-urls http://10.189.6.154:2380 --listen-peer-urls http://10.189.6.154:2380 --listen-client-urls http://10.189.6.154:2379,http://127.0.0.1:2379 --advertise-client-urls http://10.189.6.154:2379 --initial-cluster-token etcd-cluster-1 --initial-cluster master=http://10.189.6.153:2380,node1=http://10.189.6.154:2380,node2=http://10.189.6.155:2380 --initial-cluster-state new --data-dir=/usr/local/etcd --max-wals 2 --max-snapshots 2 --snapshot-count 2000000000 --quota-backend-bytes 8589934592 --auto-compaction-retention 1

Restart=on-failure
RestartSec=5
LimitNOFILE=655360

[Install]
WantedBy=multi-user.target


155配置：
[Unit]
Description=etcd server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/usr/local/etcd/
EnvironmentFile=-/usr/local/etcd/etcd.conf
ExecStart=/usr/local/etcd/etcd-v3.3.10-linux-amd64/etcd --name node2 --initial-advertise-peer-urls http://10.189.6.155:2380 --listen-peer-urls http://10.189.6.155:2380 --listen-client-urls http://10.189.6.155:2379,http://127.0.0.1:2379 --advertise-client-urls http://10.189.6.155:2379 --initial-cluster-token etcd-cluster-1 --initial-cluster master=http://10.189.6.153:2380,node1=http://10.189.6.154:2380,node2=http://10.189.6.155:2380 --initial-cluster-state new --data-dir=/usr/local/etcd --max-wals 2 --max-snapshots 2 --snapshot-count 2000000000 --quota-backend-bytes 8589934592 --auto-compaction-retention 1

Restart=on-failure
RestartSec=5
LimitNOFILE=655360

[Install]
WantedBy=multi-user.target

```

### etcd客户端

```
按照上述的安装方式etcd客户端，etcdctl已经安装了。
默认是v2版本。

v3 版本需要加环境变量。
ETCDCTL_API=3 
如
ETCDCTL_API=3 etcdctl --help
或者将ETCDCTL_API=3 放到/etc/profile中

v2常见命令：
etcdctl cluster-health
etcdctl member list
etcdctl set name wadeson
etcdctl get name

v3常见命令：
获取带prefix的节点：
time etcdctl get /deploy/agent/server --prefix

获得节点信息：
etcdctl endpoint status --write-out="json"
[{"Endpoint":"127.0.0.1:2379","Status":{"header":{"cluster_id":6123838546912185538,"member_id":10142224069671114011,"revision":1436742,"raft_term":42},"version":"3.3.10","dbSize":225685504,"leader":8731973843455329053,"raftIndex":2776994,"raftTerm":42}}]

带--endpoint执行：
etcdctl --endpoints=10.189.200.25:2379 endpoint status --write-out="json"

```

### 调优

```
除了使用上面的服务端配置外。
1，最好使用ssd
2，如果有条件的话，快照和wal分别使用两块不同的ssd
3，提高etcd的磁盘io优先级
     ionice -c2 -n0 -p `pgrep etcd`
     ionice -c1  -p `pgrep etcd`

```

### etcd优化脚本

```
vim /usr/local/etcd/etcd_defrag.sh

#!/bin/bash
# 获取版本号
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



加入crontab
*/3 * * * * /usr/local/etcd/etcd_defrag.sh >> /usr/local/etcd/etcd_defrag.log
```