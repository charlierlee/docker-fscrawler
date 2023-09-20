## Setup

```
sudo snap install microk8s --channel=latest/edge --classic <-- worked
microk8s enable gpu  
^ The gpu depends on the host machine having a working gpu
#to update --> sudo snap refresh microk8s --classic --channel=latest/edge

microk8s enable registry

sudo apt-get install iptables-persistent
sudo iptables -P FORWARD ACCEPT
sudo nano /etc/docker/daemon.json
{
    "insecure-registries" : ["master-0.local:32000"] 
}
sudo systemctl restart docker
#test http://master-0.local:32000/v2/summary
microk8s inspect
#microk8s add-node

docker push master-0.local:32000/es-init:1.0.108
docker push master-0.local:32000/tester:1.0.108
docker push master-0.local:32000/fileserver:1.0.108
docker push master-0.local:32000/fscrawler:1.0.108
docker push master-0.local:32000/elasticsearch1:1.0.108
docker push master-0.local:32000/elasticsearch-client:1.0.108
#docker push master-0.local:32000/deepdetectgpu:1.0.108
#kubectl create namespace search


#helm install microk8s-fscrawler ./microk8s/chart --namespace search
helm upgrade microk8s-fscrawler ./microk8s/chart --namespace search

# after while you can delete the es-init deployment
Go back to setup.sh



# Index Troubleshooting
    curl -XDELETE elasticsearch1:9200/docker-compose
    curl -XDELETE elasticsearch1:9200/docker-compose_folder

    curl -XPUT -H 'Content-Type: application/json' 'elasticsearch1:9200/docker-compose/_settings' -d '
    {
        "index" : {
            "number_of_replicas" : 1
        }
    }'

    curl -XPUT -H 'Content-Type: application/json' 'elasticsearch1:9200/docker-compose_folder/_settings' -d '
    {
        "index" : {
            "number_of_replicas" : 5
        }
    }'

    curl -XPOST 'localhost:9200/_cluster/reroute' -d '{
        "commands": [{
            "allocate": {
                "index": "docker-compose",
                "shard": 0,
                "node": "search03",
                "allow_primary": 1
            }
        }]
    }' 

    curl -XPOST -d '{ "commands" : [ {
    "allocate" : {
        "index" : "docker-compose", 
        "shard" : 0, 
        "node" : "Fo2G1cR",
        "allow_primary":true 
        } 
    } ] }' http://localhost:9200/_cluster/reroute?pretty


# how to add labels to pods
    microk8s kubectl label deployment/elasticsearch-client release-version=1.0
    microk8s kubectl label deployment/es-init release-version=1.0
    microk8s kubectl label deployment/fileserver release-version=1.0
    microk8s kubectl label deployment/fscrawler release-version=1.0
    microk8s kubectl label deployment/deepdetectgpu release-version=1.0
    microk8s kubectl label deployment/elasticsearch1 release-version=1.0

    microk8s kubectl label service/elasticsearch-client release-version=1.0
    microk8s kubectl label service/fileserver release-version=1.0
    microk8s kubectl label service/deepdetectgpu release-version=1.0
    microk8s kubectl label service/elasticsearch1 release-version=1.0

    microk8s kubectl label pods/fileserver-8448b6c56-6jb7p release-version=1.0
    microk8s kubectl label pods/fscrawler-6fd87c8458-ffkdx release-version=1.0
    microk8s kubectl label pods/deepdetectgpu-75c7f4bdf-w5xjl release-version=1.0
    microk8s kubectl label pods/elasticsearch-client-855f4fd88-cgmjl release-version=1.0
    microk8s kubectl label pods/elasticsearch1-6788c48677-zx56v release-version=1.0
    microk8s kubectl label pods/es-init-6675fbbfdd-tdw28 release-version=1.0

    microk8s kubectl get all --selector release-version=1.0
    microk8s kubectl get all -l 'release-version in (1.0)' --show-labels

    microk8s kubectl get pods --selector release-version=1.0
    microk8s kubectl get pods -l 'release-version in (1.0)' --show-labels
```