# docker-fscrawler [![Build Status](https://travis-ci.org/shadiakiki1986/docker-fscrawler.svg?branch=master)](https://travis-ci.org/shadiakiki1986/docker-fscrawler)

![alt text](https://github.com/charlierlee/docker-fscrawler/blob/master/screenshot.png?raw=true)

# After Fork

- Added deepdetect to index images
- Added Angular front end to view/download search results

# Proir to Fork
Dockerfile for [fscrawler](https://github.com/dadoonet/fscrawler)

Published on docker hub [here](https://hub.docker.com/r/shadiakiki1986/fscrawler/).

Mostly inspired by elasticsearch's alpine [dockerfile](https://github.com/docker-library/elasticsearch/blob/f2e19796b765e2e448d0e8c651d51be992b56d08/5/alpine/Dockerfile)

Supported tags

- `2.2` with fscrawler version 2.2 and alpine 3.5
- `2.4` with fscrawler 2.4 and alpine 3.5
- `2.5` with fscrawler 2.5 and ubuntu 16.04
- `2.6` with fscrawler 2.6 and ubuntu 20.04
  - Note: the binary name `fscrawler-es5` is compatible with elasticsearch version 5, versus `fscrawler` and `fscrawler-es6` with version 6
- (WIP) `2.7-SNAPSHOT-v20201204`
  - Note: the binary name `fscrawler-es6` is compatible with elasticsearch version 6, versus `fscrawler` and `fscrawler-es7` with version 7

Dockerfile includes [tesseract](https://github.com/tesseract-ocr/tesseract/wiki) (via ubuntu 20.04)


## Usage Instructions

### stand-alone docker

Given you have good docker-fu skills,
to run fscrawler docker image in `folder indexing mode`:

```
docker run \
  -it --rm --name my-fscrawler \
  -v <data folder>:/usr/share/fscrawler/data/:ro \
  -v <config folder>:/usr/share/fscrawler/config-mount/<project-name>:ro \
  shadiakiki1986/fscrawler \
  [CLI options]
```

where
* *data folder* is the path to the folder with the files to index
* *config folder* is the path to the host fscrawler [config dir](https://github.com/dadoonet/fscrawler#cli-options)
  * make sure to use the proper URL reference in the config file to point to the elasticsearch instance
    * e.g. `localhost:9200` if elasticsearch is running locally
* if the config folder is not mounted from the host, the docker container will have an empty `config` folder, thus prompting the user for confirmation `Y/N` of creating the first project file
* *CLI options* are documented [here](https://fscrawler.readthedocs.io/en/latest/admin/cli-options.html#cli-options)


An example set of `CLI options` is to run fscrawler in REST API mode:

```
docker run \
  ...
  -p <local port>:8080
  shadiakiki1986/fscrawler \
  --loop "0" --reset fscrawler_rest
```


### with docker-compose (file 1)

Given you already have good docker-compose-fu skills, check `docker-compose.yml`.

To use

```
echo "vm.max_map_count=262144"| sudo tee -a /etc/sysctl.conf
docker-compose pull
docker-compose build
docker-compose up
```


### with docker-compose (file 2)

Docker-fscrawler can be used in coordination with an elasticsearch docker container or an elasticsearch instance running natively on the host machine. To make coordination between the ES and
fscrawler containers easy, it is recommended to use docker-compose, as described here.
 
Make sure you have set up `vm.max_map_count=262144` by either putting it in `/etc/sysctl.conf` and 
running `sudo sysctl -p`, or whatever other means is convenient to you. This is necessary for elasticsearch. (see 
[Ref](https://github.com/docker-library/elasticsearch/issues/111))


#### Download

Download the following files from this git repository. Cloning the whole repository is _not_ necessary.

- `docker-compose.yml` (single-node) or `docker-compose-deployment.yml` (multi-node)
- `build/elasticsearch/docker-healthcheck`
 
Make a new empty folder and put these two files in it. This directory will be the home of your configurations, and the 
location from which you can control your containers and make changes.
 
Change the name of `docker-compose-deployment.yml` to `docker-compose.yml`.


###### Optional: Configure Containers

* Make a file here called `.env`. Here you can configure the docker containers.
* Add the line `TARGET_DIR=/path/to/directory/you/want/to/index`. If you don't add this line, it will default to `./data/`
* Add the line `JOB_NAME=name_to_give_your_index`. This will be the name of the fscrawler job and the ES index. 
If you don't add this line, it will default to `fscrawler_job`.

#### Configure fscrawler

Now run

```bash
docker-compose run fscrawler
```

Respond with `Y` to the question of whether to create a new config.

Edit the newly created `config/fscrawler_job/_settings.json` file (you may need to use sudo, the folder name may be 
different if you are using `.env`). Change elasticsearch.nodes from `127.0.0.1` to
`elasticsearch1`, so that it reads follows. 

```json
...
  "elasticsearch" : {
    "nodes" : [ {
      "host" : "elasticsearch1",
      "port" : 9200,
      "scheme" : "HTTP"
    } ],
    "bulk_size" : 100,
    "flush_interval" : "5s"
  },
...
```

For the rest of the settings in this file, can choose your own based on 
[the options documented here](https://fscrawler.readthedocs.io/en/latest/admin/fs/local-fs.html#). Do not change fs.url 
unless you also change the corresponding line in `docker-compose.yml`, or else fscrawler won't be able to find your 
files.


#### Test

Populate `data/` or the directory you specified in `.env` with some files you would like to index.

Run the following.

```bash
docker-compose up -d elasticsearch1 elasticsearch2
docker-compose up -d fscrawler
```

fscrawler should then upload the test files you put in `data/`. To check that all is well, 
query the elasticsearch over http (substitute fscrawler_job if you gave it your own name in `.env`)

```bash
curl http://localhost:9200/fscrawler_job/_search | jq
```

If you see all your documents here, you should be good to go!

#### Troubleshooting

If you don't see all your documents, use the following command to get more detailed logs. 

```bash
docker-compose run fscrawler --config_dir /usr/share/fscrawler/config fscrawler_job --restart --debug
```

Hopefully these logs will make it clear what went wrong. Failing that you can use 
`--trace` instead of `--debug` for even more detailed logs. You can also use `--restart` whenever you want to re-index 
everything (otherwise files are only reindexed when they are touched).

Additional options for `docker-compose run fscrawler` can be found 
[here](https://github.com/dadoonet/fscrawler#cli-options).


## Additional Usage Examples

### Example 1
Using `docker-compose`, startup elasticsearch and run fscrawler on files in `test/data` every 15 minutes:

```bash
docker-compose up elasticsearch1 fscrawler
```

For the remaining examples, the default config depends on having a running elasticsearch instance on the localhost at port 9200.
Start one with:

```bash
# [Ref](https://github.com/docker-library/elasticsearch/issues/111)
sudo sysctl -w vm.max_map_count=262144

docker-compose run -p 9200:9200 -d elasticsearch1
```

For the versions of the `docker-compose` file, `docker-compose`, and `docker`, check the [travis builds](https://travis-ci.org/shadiakiki1986/docker-fscrawler/)

Notice that the docker-compose `fscrawler` service is wired to wait for a healthcheck in `elasticsearch`.
In the case of a manual launch of elasticsearch:
- wait for around 15 seconds,
- or watch the logs,
- or check `http://$host:9200/_cat/health?h=status`
where you need to wait for `yellow` or `green`, depending on your application


### Example 2
To index the test files provided in this repo

```bash
docker run -it --rm \
  --net="host" \
  --name my-fscrawler \
  -v $PWD/test/data/:/usr/share/fscrawler/data/:ro \
  shadiakiki1986/fscrawler
```

### Example 3
Same example above, but with `loop=1` to run it only once

```bash
docker run -it --rm \
  --net="host" \
  --name my-fscrawler \
  -v $PWD/test/data/:/usr/share/fscrawler/data/:ro \
  -v $PWD/config/myjob:/usr/share/fscrawler/config-mount/myjob:ro \
  shadiakiki1986/fscrawler \
    --config_dir /usr/share/fscrawler/config \
    --loop 1 \
    --trace \
    myjob
```


## Building locally

To build the docker image
```
git clone https://github.com/shadiakiki1986/docker-fscrawler
docker build -t shadiakiki1986/fscrawler:local . # or use version instead of "local"
```

To test against elasticsearch locally, follow steps in `.travis.yml`


## Updating

To update `fscrawler` in this docker container:

- install docker (instructions for linux: [link](https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script))
- install docker-compose (instructions for linux: [link](https://docs.docker.com/compose/install/))
- update the version numbers used in `Dockerfile`
  - (deprecated) also update the URL to the maven zip file to download
- test can build
  - `docker build -t shadiakiki1986/fscrawler:2.6 .`
  - `docker build -t shadiakiki1986/fscrawler:2.7-SNAPSHOT-20201204 .`

- test can run (check section above "Usage / with docker-compose (file 1)", or run tests in `.travis.yml` file)
- commit, tag, push to github

To update the automated build on hub.docker.com
- the "latest" tag will get re-built automatically with the `push` above
- to add a new version tag, need to `build settings` and add it manually, then click `save` and `trigger`

To update `elasticsearch` in the `docker-compose` for the purpose of testing (e.g. `.travis.yml`)
- edit `build/elasticsearch/Dockerfile` by changing `FROM` image
- follow steps in `.travis.yml`


## Changelog

Version 2.6 (2020-12-04)

- update fscrawler from 2.6-SNAPSHOT to 2.6
- update ubuntu base image from 16.04 to 20.04, etc
- support `fscrawler{,-es5,-es6}`


Version 2.6-SNAPSHOT (2018-10-08)
- update fscrawler from 2.5 to `2.6-SNAPSHOT` (master branch as of today)


Version 2.5.2 (2018-10-08)
- docker-compose.yml updates
  - update base elasticsearch image to be `6.4` from 6.1
  - bring back the file crawl service
  - elasticsearch healthcheck to target yellow as a "minimum" now that 6.4 shows green instead of yellow even if 1 node


Version 2.5.1 (2018-10-08)
- using fscrawler 2.5


Version 2.4.2 (2018-10-04)
- change the main base image to be ubuntu instead of alpine linux
  - move the alpine linux image into a "alpine" folder
  - move teh ubuntu linux image out of the "ubuntu" folder


Version 2.4 (2017-12-27)
- update fscrawler from 2.2 to 2.4
- use `config-mount` for mounting config folder into fscrawler docker container
- update elasticsearch service from 5.1.2 to 6.1.1
  - elasticsearch 5.1.2 was not working with fscrawler 2.4 anyway because of https://github.com/dadoonet/fscrawler/issues/472
- replace git submodule of my fork of elasticsearch-docker with just `build/elasticsearch/Dockerfile`
  - the purpose of the fork was to push healthchecks into upstream, but my PR was rejected
  - fork was at https://github.com/shadiakiki1986/elasticsearch-docker
  - PR was at https://github.com/elastic/elasticsearch-docker/pull/27
  - argumentation at https://github.com/elastic/elasticsearch-docker/issues/60
  - proposed solution of just using docker-compose healthcheck would be too long in order to wait for "green" status

Version 2.2 (2017-02-22)
-  use fscrawler 2.2
