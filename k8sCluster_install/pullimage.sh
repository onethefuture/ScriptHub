#!/bin/bash
image_name=(
        kube-apiserver:v1.25.2
        kube-controller-manager:v1.25.2
        kube-scheduler:v1.25.2
        kube-proxy:v1.25.2
        pause:3.8
        etcd:3.5.4-0
        coredns:v1.9.3
    )
tc_registry="hub.17usoft.com/kubernetes/"
aliyun_registry="registry.aliyuncs.com/google_containers/"
for image in ${image_name[@]}
do
    docker pull $aliyun_registry$image
    docker tag $aliyun_registry$image $tc_registry$image
    docker push $tc_registry$image
done




