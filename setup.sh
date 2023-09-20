# Add the package repositories
sudo apt install nvidia-cuda-toolkit
# for use in image classification service

install docker-compose via https://docs.docker.com/compose/install/


# Important: do on the server
mkdir /home/alice/esdata
mkdir /home/alice/share
chmod +r /home/alice/share
mkdir /home/alice/docker-compose
sudo mkdir /opt/models/
# Important: run from here
scp config/docker-compose/* alice@master-0.local:/home/alice/docker-compose
scp ~/Downloads/search/* alice@master-0.local:/home/alice/share


#start
cd client
npm install
npm run buildprod
cd ../
docker-compose build
#OR to redeploy just one part:
#docker-compose build elasticsearch-client
#docker-compose up

# go to microk8s/Readme.md for next steps then go back here
# Once complete, return here

#https://www.deepdetect.com/tutorials/es-image-classifier/
# 1. create images index
curl -X PUT "https://elasticsearch.leenet.link/images" -H 'Content-Type: application/json' -d'{ "settings" : { "index" : { } }}'
# 2A. make sure you already did this: sudo apt install nvidia-cuda-toolkit
# ^ This should have been done before microk8s enable gpu
# 2B. create service for image classification
curl -X PUT 'https://deepdetectgpu.leenet.link/services/ilsvrc_googlenet' -d '{
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

# 3. test a single image (does not show up in search engine)
# go to step 4 to test
curl -X POST "https://deepdetectgpu.leenet.link/predict" -d '{
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
             "url":"https://elasticsearch.leenet.link/images/img",
             "http_method":"POST"
           }
         }
       },
       "data":["http://deepdetect.com/img/examples/interstellar.jpg"]
     }'

# Step 4, test
https://elasticsearch.leenet.link/images/_search?q=helmet

# Step 5, run image_classify once. Note: If you run it twice you will get dups
