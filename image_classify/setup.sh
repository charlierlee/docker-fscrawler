#setup
cd ./image_classify
python3 -m venv ./env
source env/bin/activate
pip install -r requirements.txt
#cd ../ #outside of git repo
#git clone https://github.com/jolibrain/deepdetect.git
#cd deepdetect
#cd clients/python
#pip install .
#cd ../../../docker-fscrawler

#run
cd ./image_classify
source env/bin/activate
python crawl.py

#to delete index
#curl -XDELETE localhost:9200/images
