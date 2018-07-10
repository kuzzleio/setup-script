# analytics-proxy

A multi-channel Analytics server for the Kuzzle setup.sh script. By "multi-channel", we mean that it handles the events to the
following channels:

- forward events to Google Analytics
- notify users via email
- locally log events

## Configuration

We rely on `rc` for the configuration. Take a look at `.analyticsrc.sample` for a list of available options.

If a feature is not configured (say you omit the `mail` attribute), it means it's disabled.

You can also choose the port to listen onto via the 1st level `port` attribute (defaulting to `3000`).

Note that configuration can be overridden via environment variables (see also https://github.com/dominictarr/rc#standards)

## Run

```bash
$ npm start
```

## Integration tests

We don't have an automatic test suite, but instead a manual process to ensure that events from setup.sh are properly handled
by a given instance of the analytics proxy.

### Manually send cUrl requests to the proxy

For this to work, you'll need a valid (i.e. 64 chars-long) UID:

```bash
export SETUPSH_UID=$(LC_CTYPE=C tr -dc A-Fa-f0-9 < /dev/urandom | fold -w 64 | head -n 1)
```

Here's a sample request:

```bash
curl -H Content-Type:application/json --data "{\"type\": \"$TEST_EVENT\", \"uid\": \"$SETUPSH_UID\", \"os\": \"DEBIAN\"}" $ANALYTICS_URL
```

Put the URL of your instance of the proxy in `$ANALYTICS_URL`. You can put whatever you want in `$TEST_EVENT`.

### Override the default proxy URL in setup.sh

You can simply run setup.sh by using a custom analytics proxy with a custom value in the `$ANALYTICS_URL` environment variable. From the root of this repo, type:

```bash
ANALYTICS_URL=http://my.analytics.proxy.server/ ./setup.sh
```

### Override the default proxy URL in a whole test suite

You can also run a whole test suite with a custom value in the `$ANALYTICS_URL` environment variable. From the root of this repo, type:

```bash
ANALYTICS_URL=http://my.analytics.proxy.server/ SETUPSH_TEST_DISTROS=debian-jessie test/run.sh
```
