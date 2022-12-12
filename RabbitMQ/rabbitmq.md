### rabbitmq与kafka比较

```
kafka也为一种mq。
其与传统的mq还是有很多不同的。

针对mq是否能用于当前日志系统，部分取代kafka的问题：
以rabbitmq为例，当前了解是不行。

首要问题是性能问题，kafka单机十万级别，rabbitmq单机为万级。
我们的日志系统，经常超过十万每秒的处理。
此外kafka分布式，常规架构就能高可用，方便水平扩展。
用在日志系统，大数据系统最合适。

同时kafka也无法取代rabbitmq：
很重要的一点就是kafka的延迟太高，为毫秒级。满足不了线上业务需求。
其次kafka消息无序，对有序要求的场景，满足不了。

```

### 高可用实施思路

```
把上述高可用方案实施。

基本思路：
首先搭建rabbit集群，设置使用镜像模式。
然后使用tvs负载均衡的高可用。

rabbitmq镜像模式配置：
镜像队列是基于普通的集群模式的，所以还是得先配置普通集群，然后才能设置镜像队列。
开通镜像模式有以下两种方法：
1，通过web节点设置，具体见web界面
2，通过命令行的方式：（集群搭建完成后，在主节点执行）
    rabbitmqctl set_policy ha-all "^" '{"ha-mode":"all"}'
    将所有队列设置为镜像队列，即队列会被复制到各个节点，各个节点状态保持一致。

查看：
rabbitmqctl list_policies
Listing policies for vhost "/" ...
vhost   name    pattern apply-to        definition      priority
/       ha-all  ^       all     {"ha-mode":"all"}       0


此时镜像集群就已经完成了，可以在任意节点上创建队列，自动同步到其他节点。

```

### rabbitmq 单机和集群部署

```

单机版rabbitmq部署：
安装erlang：
# 编辑erlang yum repo
vim /etc/yum.repos.d/rabbitmq_erlang.repo

[rabbitmq_erlang]
name=rabbitmq_erlang
baseurl=https://packagecloud.io/rabbitmq/erlang/el/7/$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/erlang/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[rabbitmq_erlang-source]
name=rabbitmq_erlang-source
baseurl=https://packagecloud.io/rabbitmq/erlang/el/7/SRPMS
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/erlang/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

# 安装erlang
yum install erlang -y

# 导入mq签名
rpm --import https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc

# 编辑rabbitmq yum repo
vim /etc/yum.repos.d/rabbitmq.repo

[bintray-rabbitmq-server]
name=bintray-rabbitmq-rpm
baseurl=https://dl.bintray.com/rabbitmq/rpm/rabbitmq-server/v3.8.x/el/7/
gpgcheck=0
repo_gpgcheck=0
enabled=1

# 安装 rabbitmq
yum install rabbitmq-server -y

# 启动服务并设置开机自启动
systemctl start rabbitmq-server 
systemctl enable rabbitmq-server

# 开启管理界面
rabbitmq-plugins enable rabbitmq_management

# 设置账户相关
rabbitmqctl add_user username passwd
rabbitmqctl set_user_tags username administrator
rabbitmqctl set_permissions -p / username ".*" ".*" ".*"

以上是单机的rabbitmq部署步骤，可以登录 ip:15672 管理界面查看，是否一切正常。

以下是集群部署部分，在所有节点都装好单机的基础上：
(操作的时候，最好关闭从的rabbitmq： 
systemctl stop rabbitmq-server
此步骤不一定需要，如果在此关，后面要相应的开启)

# 互设hosts方便访问
vim /etc/hosts
互相添加节点的hosts
特别重要的是：
如果一个节点的hosts是：
10.189.6.100 wjfh-189-6-100.linux.17usoft.com

rabbit 启动之后他的node是：
rabbit@wjfh-189-6-100

所以还要添加下面的hosts：
10.189.6.100 wjfh-189-6-100

# scp 主节点到 .erlang.cookie 到从节点上
/var/lib/rabbitmq/.erlang.cookie 
（最好scp操作文件，直接编辑文件，可能会有问题）

注：
后续可能出现：
“when reading /var/lib/rabbitmq/.erlang.cookie: eacces”
从上执行：
chown rabbitmq:rabbitmq .erlang.cookie
chmod 400 .erlang.cookie

注：
如果上面关闭了从，在这里需要开启。


# 加入集群操作
主：
rabbitmqctl stop
rabbitmq-server -detached

rabbitmqctl cluster_status

从：
rabbitmqctl stop_app
rabbitmqctl join_cluster rabbit@主  (例子如 rabbit@wjfh-189-6-100)
rabbitmqctl start_app

rabbitmqctl cluster_status

然后按照上面说的部署镜像模式。

```

### rabbitmq 3.8.6 单机版本搭建

```
上面的依赖yum搭建的rabbitmq单机版搭建方式，因为网站的调整，现在有问题了。
yum安装erlang没有问题。
yum安装rabbit有问题。
且中间的那步 导入mq签名 也有问题。需要下载下来，本地导入。

以此为准：

单机版rabbitmq部署：
安装erlang：
# 编辑erlang yum repo
vim /etc/yum.repos.d/rabbitmq_erlang.repo

[rabbitmq_erlang]
name=rabbitmq_erlang
baseurl=https://packagecloud.io/rabbitmq/erlang/el/7/$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/erlang/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[rabbitmq_erlang-source]
name=rabbitmq_erlang-source
baseurl=https://packagecloud.io/rabbitmq/erlang/el/7/SRPMS
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/erlang/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

# 安装erlang
yum install erlang -y

# 导入mq签名
rpm --import https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc
注：
此步骤如果不通，可以使用本地下载导入。
rpm --import rabbitmq-release-signing-key.asc


# 编辑rabbitmq yum repo
rpm -ivh rabbitmq-server-3.8.6-1.el7.noarch.rpm


# 启动服务并设置开机自启动
systemctl enable rabbitmq-server
systemctl start rabbitmq-server 


# 开启管理界面
rabbitmq-plugins enable rabbitmq_management

# 设置账户相关
rabbitmqctl add_user username passwd
rabbitmqctl set_user_tags username administrator
rabbitmqctl set_permissions -p / username ".*" ".*" ".*"

# 然后根据需要安装插件

```

### 最简配置文件

```
# 我们默认使用的9073 amqp, 9075 http web ui
配置文件
vim /etc/rabbitmq/rabbitmq.config 
   [
   	   {rabbitmq_management, [
		   {listener, 
				[{port,     9075},
				{ip,       "0.0.0.0"},
				{ssl,     false}
				]}
		]},
		
       {rabbit, [
           {tcp_listeners, [9073]}
       ]}
   ].

```

### rabbitmq 默认接口

```
4369 (epmd), 25672 (Erlang distribution)
5672, 5671 (AMQP 0-9-1 without and with TLS)
15672 (if management plugin is enabled)
61613, 61614 (if STOMP is enabled)
1883, 8883 (if MQTT is enabled)

```

### 插件

```
安装插件必需在所有节点都安装：

查看插件列表：
rabbitmq-plugins list


目前已经安装的插件：
延时队列参考
《rabbitmq延时队列》


rabbitmq_stomp
直接执行enbale即可
rabbitmq-plugins enable rabbitmq_stomp


查看哪些top模块在消耗资源（疑似是的）
rabbitmq-plugins enable rabbitmq_top

```

### 日志和数据

```
路径目录：
配置文件
Config file	/etc/rabbitmq/rabbitmq.config
数据路径
Database directory	/var/lib/rabbitmq/mnesia/rabbit@wjfh-189-6-149
日志	
/var/log/rabbitmq/rabbit@wjfh-189-6-149.log
/var/log/rabbitmq/rabbit@wjfh-189-6-149_upgrade.log

遇到的问题：
rabbitmq重启之后依旧有问题，无法正常使用。
把数据删掉就可以了。
/var/lib/rabbitmq/mnesia/rabbit@wjfh-189-6-102/quorum/rabbit@wjfh-189-6-102/00000001.wal

```

### 域名配置

```
如果需要使用域名，需要设置path_prefix

/etc/rabbitmq/rabbitmq.config 如下：

   [
           {rabbitmq_management, [
                   {listener,
                                [{port,     9075},
                                {ip,       "0.0.0.0"},
                                {ssl,     false}
                                ]},
                                {path_prefix, "/mq05"}
                ]},

       {rabbit, [
           {tcp_listeners, [9073]}
       ]}
   ].

```

### 配置和调优

```
按照上面方式安装的。
配置文件用/etc/rabbitmq/rabbitmq.config
还有/usr/lib/systemd/system/rabbitmq-server.service

工作路径：
/var/lib/rabbitmq/

日志路径：
/var/log/rabbitmq/


修改链接数限制：
修改/usr/lib/systemd/system/rabbitmq-server.service
的
LimitNOFILE=327680

重启：
systemctl daemon-reload
systemctl restart rabbitmq-server

限制的是：
File descriptors
Socket descriptors 约等于 LimitNOFILE * 0.9


如果系统配置的比LimitNOFILE小，还要调大系统配置：
/etc/sysctl.conf
/etc/security/limits.conf

rabbitmq 的 socket limit满时：
RabbitMQ不再接收的是AMQP连接，而不是传输层的TCP连接

line 2-4是TCP握手包，成功建立TCP连接。line5开始客户端向服务器端发送AMQP协议头字符串“AMQP0091”，共8个字节，开始AMQP握手。line 6是服务器回给客户端的ack包，但未发送AMQP connection.start方法，导致客户端一直等到超时(line 7-8)，发送FIN包关闭TCP连接。至此，AMQP连接建立失败。

```

### 针对大量连接数做的优化

```
表现：
web ui上看大量的socket 链接数爆满，然后导致服务不可用了。
发现有大量的CLOSE_WAIT

针对CLOSE_WAIT想解决办法和调大文件数限制。

修改
/usr/lib/systemd/system/rabbitmq-server.service
LimitNOFILE=327680

系统变量：
echo 120 > /proc/sys/net/ipv4/tcp_keepalive_time
echo 2 > /proc/sys/net/ipv4/tcp_keepalive_intvl
echo 1 > /proc/sys/net/ipv4/tcp_keepalive_probes

注意：
上面的调整，会引发其他的问题，后来又调整回原配置了

```

### rabbitmq消息持久化

```
上面配置的有镜像模式。
但是rabbitmq本身的持久化是通过，业务程序控制的。

队列持久化需要在声明队列时添加参数 durable=True，这样在rabbitmq崩溃时也能保存队列
仅仅使用durable=True ，只能持久化队列，不能持久化消息
消息持久化需要在消息生成时，添加参数 properties=pika.BasicProperties(delivery_mode=2)


目前已知的rabbitmq并没有配置项，来关闭全局持久化。
```