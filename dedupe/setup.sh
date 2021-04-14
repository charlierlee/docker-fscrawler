#setup
cd ./dedupe
python3 -m venv ./env
source env/bin/activate
pip install -r requirements.txt


#run
cd ./dedupe
source env/bin/activate
python dedupe.py

#to delete index
#curl -XDELETE localhost:9200/images
