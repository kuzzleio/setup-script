FROM node:6
MAINTAINER Kuzzle <tech@kuzzle.io>

COPY ./run.sh /
WORKDIR /var/app

RUN chmod +x /run.sh && \
    npm i -g pm2
