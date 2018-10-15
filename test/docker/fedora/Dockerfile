FROM fedora:28

LABEL io.kuzzle.vendor="Kuzzle <support@kuzzle.io>"

RUN dnf install -y -q \
  expect \
  iproute \
  ncurses

WORKDIR /opt/test

CMD [ "tail", "-f", "/dev/null" ]
