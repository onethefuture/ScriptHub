IP_LIST="192.168.100.10 192.168.100.20 192.168.100.30"
CLUSTER_NAME="etcd_cluster"
tar xzvf etcd-v3.4.7.tgz -C / && cd / && bash -x setup.sh $CLUSTER_NAME $IP_LIST
                                                                                                                                 