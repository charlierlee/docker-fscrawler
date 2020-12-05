original dockerfile for fscrawler was based on alpine linux

but then I replaced the alpine linux base image with the ubuntu one

and moved the older one in here, and the ubuntu one out of the "ubuntu" folder

----------------------------

Here is the README section from "ubuntu" subfolder

Basically a copy of alpine/Dockerffile and alpine/entry.sh but with ubuntu:16.04
Based on file published by  alcibiade here
https://github.com/dadoonet/fscrawler/issues/314#issuecomment-282823207

Main differences
- gosu instead of su-exec
- adaduser/addgroup options different than busybox (alpine)

Build
```
cd docker-fscrawler
docker build -t shadiakiki1986/fscrawler:2.5-SNAPSHOT-ubuntu ubuntu
```

Old notes: The Ubuntu image was added because the alpine image was giving an error upon `mvn clean install`
It said that `initial heap size larger than max heap size` and I couldn't figure it out.
The alpine image was 308 MB, whereas the ubuntu image is 1.2 GB (but also includes tesseract-fra).
Probably a good idea to get the alpine image to work.

