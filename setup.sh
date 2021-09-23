# Add the package repositories

wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/7fa2af80.pub
sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /"
sudo apt-get update
sudo apt-get -y install cuda
#if fail: sudo apt clean; sudo apt update; sudo apt purge cuda; sudo apt purge nvidia-*; sudo apt autoremove; sudo apt install cuda

#upgrade docker-compose
VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq .name -r)
DESTINATION=/usr/local/bin/docker-compose
sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m) -o $DESTINATION
sudo chmod 755 $DESTINATION

#install nvidia-container-toolkit give docker-compose access to the gpu
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit nvidia-container-runtime nvidia-docker2
sudo systemctl restart docker
#^ if docker-compose up fails, reboot

#for docker-compose.yml restart: always feature,
# make docker run as a service
sudo systemctl enable docker

# Important: do on the server
mkdir /home/alice/esdata

#start
cd client
npm install
npm run buildprod
cd ../
docker-compose build elasticsearch_client
docker-compose up -d


#https://www.deepdetect.com/tutorials/es-image-classifier/

curl -X PUT 'http://elasticsearch1:8080/services/ilsvrc_googlenet' -d '{
 "description": "image classification service",
 "model": {
  "repository": "/opt/models/ilsvrc_googlenet",
  "init": "https://deepdetect.com/models/init/desktop/images/classification/ilsvrc_googlenet.tar.gz",
  "create_repository": true
 },
 "mllib": "caffe",
 "type": "supervised",
 "parameters": {
  "input": {
   "connector": "image"
  }
 }
}'

#test
#cannot use localhost
curl -X POST "http://elasticsearch1:8080/predict" -d '{
       "service":"ilsvrc_googlenet",
       "parameters":{
         "mllib":{
           "gpu":true
         },
         "input":{
           "width":224,
           "height":224
         },
         "output":{
           "best":3,
           "template":"{ {{#body}}{{#predictions}} \"uri\":\"{{uri}}\",\"categories\": [ {{#classes}} { \"category\":\"{{cat}}\",\"score\":{{prob}} } {{^last}},{{/last}}{{/classes}} ] {{/predictions}}{{/body}} }",
           "network":{
             "url":"http://elasticsearch1:9200/images/img",
             "http_method":"POST"
           }
         }
       },
       "data":["http://deepdetect.com/img/examples/interstellar.jpg"]
     }'

#test
http://elasticsearch1:9200/images/_search?q=helmet