# analytics-proxy

A modular Analytics server for the Kuzzle setup.sh script. By "modular", we mean that it can do all or none of the following things

* forward events to Google Analytics
* notify users via email
* locally log events

## Configuration

We rely on `rc` for the configuration. Take a look at `.analyticsrc.sample` for a list of available options.

If a feature is not configured (say you omit the `mail` attribute), it means it's disabled.

You can also choose the port to listen onto via the 1st level `port` attribute (defaulting to `3000`).

Note that configuration can be overridden via environment variables (see also https://github.com/dominictarr/rc#standards)

## Run

```bash
$ npm start
```
