#!/bin/bash
systemctl stop firewalld
setenforce 0
sed -i 's/^SELINUX=.\*/SELINUX=disabled/' /etc/selinux/config

swapoff -a
install="yum -y install"
cat > /etc/sysctl.d/k8s.conf << EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
lsmod | grep ip_vs
lsmod | grep nf_conntrack_ipv4
rpm -qa|grep ipvsadm-1.27-8.el7.x86_64
if [ $? -eq 1 ];then 
  $install ipvsadm
fi
modprobe br_netfilter 
echo "====================================================基础环境已准备==================================================="
sleep 1

echo "install etcd cluster !!!"
IP_LIST="10.181.20.72"
CLUSTER_NAME="etcd_cluster"
mv etcd-v3.4/* / && cd / && bash -x setup.sh $CLUSTER_NAME $IP_LIST
systemctl start etcd && systemctl enable etcd 
if [ $? -eq 0 ];then
  echo "===========================================================etcd服务正常启动==========================================="
else
  echo "etcd install error"
  exit
fi

wget -c  http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
mv ./docker-ce.repo /etc/yum.repos.d/

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

rpm -qa|grep container-selinux-2.119.2-1.911c772.el7_8.noarch
if [ $? -eq 1 ];then
  yum -y remove container-selinux && \
  wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo && \
  $install  container-selinux
fi

rpm -qa|grep containerd.io
if [ $? -eq 1 ];then
  $install containerd
fi

containerd config default | tee /etc/containerd/config.toml   
sed -i 's/sandbox_image = "registry.k8s.io\/pause:3.6"/sandbox_image = "registry.aliyuncs.com\/google_containers\/pause:3.8"/g' /etc/containerd/config.toml   
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml    
sed -i 's/io.containerd.runc.v2/io.containerd.runtime.v1.linux/g' /etc/containerd/config.toml

systemctl restart containerd
#crictl images| grep dockershim 
#if [[ $? -eq 1 ]];then
#  crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
#fi
#crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
#crictl config image-endpoint unix:///run/containerd/containerd.sock

mkdir -p /data/logs/kubernetes
$install  kubelet kubeadm kubectl 
systemctl daemon-reload ; systemctl restart kubelet ; systemctl enable kubelet
crictl images| grep dockershim
if [[ $? -eq 1 ]];then
  crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
fi
kubeadm config images list
crictl image
if [[ $? -eq 0 ]];then
  echo "=========================================================kubeadm已安装完成===================================================="
  echo "####Go to run 'kubeadm init --config kubeadm-config.yaml --upload-certs'"
fi


