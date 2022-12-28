# k8s日志系统

## 集群架构

### FileBeats + Kafka + ELK 

#### FileBeats

用于转发和集中日志数据的轻量级托运器。 

#### kafka

一种高吞吐量的分布式发布订阅消息系统，它能帮助我们削峰。ELK也可以使用redis作为消息队列，但redis作为消息队列不是强项而且redis集群不如专业的消息发布系统kafka。 

#### logstash

主要是用来日志的搜集、分析、过滤日志的工具，支持大量的数据获取方式。 

#### elasticsearch

Elasticsearch是个开源分布式搜索引擎，提供搜集、分析、存储数据三大功能。它的特点有：分布式，零配置，自动发现，索引自动分片，索引副本机制，restful风格接口，多数据源，自动搜索负载等。 

#### kibana

Kibana可以为 Logstash 和 ElasticSearch 提供的日志分析友好的 Web 界面，可以帮助汇总、分析和搜索重要数据日志。 

![1671698293270](https://img-blog.csdnimg.cn/2b28e64097b84aa594786aeff6ba381f.png#pic_center)

​	`日志采集器Logstash其功能虽然强大，但是它依赖java、`在数据量大的时候，Logstash进程会消耗过多的系统资源，这将严重影响业务系统的性能，而filebeat就是一个完美的替代者，它基于Go语言没有任何依赖，配置文件简单，格式明了，同时filebeat比logstash更加轻量级，所以占用系统资源极少，非常适合安装在生产机器上。这就是推荐使用filebeat，也是 ELK Stack 在 Agent 的第一选择。
​	此架构适合大型集群、海量数据的业务场景，它通过将前端Logstash Agent替换成filebeat，有效降低了收集日志对业务系统资源的消耗。同时，消息队列使用kafka集群架构，有效保障了收集数据的安全性和稳定性，而后端Logstash和Elasticsearch均采用集群模式搭建，从整体上提高了ELK系统的高效性、扩展性和吞吐量。我所在的项目组采用的就是这套架构，由于生产所需的配置较高，且涉及较多持久化操作，采用的都是性能高配的云主机搭建方式而非时下流行的容器搭建 

## 部署

### elasticsearch

安装方式：helm

安装版本：8.5.1

>  :zap: helm安装8版本elastic默认开启ssl认证，我们这边禁用认证

开始前奏操作，生成secret

```shell
# 根据提供的 elastic-certificates.p12 将 pcks12 中的信息分离出来，写入文件
openssl pkcs12 -nodes -passin pass:'' -in elastic-certificates.p12 -out elastic-certificate.pem

添加证书和密码到集群
# 添加证书
kubectl create secret generic elastic-certificates --from-file=elastic-certificates.p12
kubectl create secret generic elastic-certificate-pem --from-file=elastic-certificate.pem

# 设置集群用户名密码，用户名不建议修改
##命令行
kubectl create secret generic elastic-credentials \
  --from-literal=username=elastic --from-literal=password=123456
##yaml
apiVersion: v1
data:
  password: 123456
  username: admin
kind: Secret
metadata:
  name: elastic-credentials
type: Opaque
```

:black_flag: 加油特种兵

先添加elasticsearch的helm仓库，并拉取对应版本的Charts并对其解压

```shell
[root@ycloud ~]# helm repo add elastic https://helm.elastic.co
"elastic" has been added to your repositories
[root@ycloud ~]# helm pull elastic/elasticsearch --version 8.5.1
[root@ycloud ~]# tar -zxvf elasticsearch-8.5.1.tgz 
elasticsearch/Chart.yaml
elasticsearch/values.yaml
......
```

调整values

```yaml
replicas: 2
minimumMasterNodes: 1

esMajorVersion: ""

# Allows you to add any config files in /usr/share/elasticsearch/config/
# such as elasticsearch.yml and log4j2.properties

# ==================安全配置========================
protocol: http

###挂在证书，这里用我们上面创建的证书
secretMounts: 
  - name: elastic-certificates
    secretName: elastic-certificates
    path: /usr/share/elasticsearch/config/certs
    defaultMode: 0755

esConfig: 
  elasticsearch.yml: |
    xpack.security.enabled: true
    xpack.security.transport.ssl.enabled: true
    xpack.security.transport.ssl.verification_mode: certificate
    xpack.security.transport.ssl.keystore.path: /usr/share/elasticsearch/config/certs/elastic-certificates.p12
    xpack.security.transport.ssl.truststore.path: /usr/share/elasticsearch/config/certs/elastic-certificates.p12
#    key:
#      nestedkey: value
#  log4j2.properties: |
#    key = value

## 关闭ssl认证
createCert: false        
esJavaOpts: "-Xmx1g -Xms1g"

###指定elastic用户密码
extraEnvs: 
  - name: ELASTIC_USERNAME
    valueFrom:
      secretKeyRef:
        name: elastic-credentials    ###用我们创建的secret
        key: username
  - name: ELASTIC_PASSWORD
    valueFrom:
      secretKeyRef:
        name: elastic-credentials		###用我们创建的secret
        key: password
###true开启持久化
persistence:
  enabled: true
```

### kibana

安装方式：helm

安装版本：8.5.1

> :zap:: 默认使用身份验证和TLS部署Kibana 8.5.1连接到Elasticsearch 