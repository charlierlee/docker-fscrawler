sudo snap install microk8s --channel=latest/edge --classic <-- worked
microk8s enable gpu  
^ The gpu depends on the host machine having a working gpu
#to update --> sudo snap refresh microk8s --classic --channel=latest/edge

microk8s enable registry

sudo apt-get install iptables-persistent
sudo iptables -P FORWARD ACCEPT
sudo nano /etc/docker/daemon.json
{
    "insecure-registries" : ["localhost:32000"] 
}
sudo systemctl restart docker
#test http://localhost:32000/v2/summary
microk8s inspect
#microk8s add-node

docker push localhost:32000/es-init
docker push localhost:32000/tester
docker push localhost:32000/fileserver
docker push localhost:32000/fscrawler
docker push localhost:32000/elasticsearch1
docker push localhost:32000/elasticsearch-client
docker push localhost:32000/deepdetectgpu


kompose --volumes hostPath convert
kompose --file docker-compose3.yml --volumes hostPath convert

microk8s.kubectl apply -f elasticsearch1-deployment.yaml,elasticsearch-client-deployment.yaml,es-init-deployment.yaml,fileserver-service.yaml,elasticsearch1-service.yaml,elasticsearch-client-service.yaml,fileserver-deployment.yaml,fscrawler-deployment.yaml

Go back to setup.sh

# Troubleshouting
    #microk8s.kubectl apply -f fscrawler-deployment.yaml
    #microk8s.kubectl apply -f elasticsearch1-deployment.yaml
    microk8s.kubectl apply -f elasticsearch-client-service.yaml
    microk8s.kubectl apply -f elasticsearch-client-deployment.yaml

    microk8s.kubectl apply -f deepdetectgpu-service.yaml
    microk8s.kubectl apply -f deepdetectgpu-deployment.yaml

    microk8s kubectl get all --all-namespaces
    microk8s kubectl rollout restart deployment elasticsearch1
    microk8s kubectl rollout restart deployment elasticsearch-client
    microk8s kubectl rollout restart deployment deepdetectgpu
    microk8s kubectl logs elasticsearch1-b46cb75d8-qd7fv
    microk8s kubectl expose deployment elasticsearch-client --type=NodePort --port=1358 --name=elasticsearch-client-service
    microk8s kubectl expose deployment elasticsearch1 --type=NodePort --port=9200 --name=elasticsearch1-service
    microk8s kubectl expose deployment fileserver --type=NodePort --port=3000 --nodePort=9200 --name=fileserver-service

    microk8s kubectl port-forward service/elasticsearch-client 1358:1358 -n default

    microk8s.kubectl describe pod
    microk8s inspect

    microk8s start
    microk8s ctr images ls
    microk8s kubectl exec -it fscrawler-7c95bc4459-tzlbm -- /bin/bash
    microk8s kubectl exec -it elasticsearch-6b87b97477-8k2sf -- /bin/bash
    microk8s stop

    # to remove all images:
    # get all images that start with localhost:32000, output the results into image_ls file
    sudo microk8s ctr images ls name~='localhost:32000' | awk {'print $1'} > image_ls 
    # loop over file, remove each image
    cat image_ls | while read line || [[ -n $line ]];
    do
        microk8s ctr images rm $line
    done;

    microk8s kubectl delete --all pods --namespace=default
    microk8s kubectl delete --all deployments --namespace=default
    microk8s kubectl delete --all service --namespace=default

    microk8s kubectl get netpol -n default
    microk8s kubectl delete netpol fscrawler-net -n default

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
