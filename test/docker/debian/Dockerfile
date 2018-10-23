FROM debian:stretch-slim

LABEL io.kuzzle.vendor="Kuzzle <support@kuzzle.io>"

RUN  set -x \
  && apt-get update \
  && apt-get install -y  \
    expect \
    iproute2

WORKDIR /opt/test

CMD [ "tail", "-f", "/dev/null" ]
