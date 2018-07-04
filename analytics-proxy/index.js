/* eslint-disable no-console */

const c = require('chalk');
const uuid = require('uuid/v5');
const ua = require('universal-analytics');
const winston = require('winston');
const nodemailer = require('nodemailer');
const hbs = require('nodemailer-express-handlebars');
const config = require('./config');
const bodyParser = require('body-parser');
const proxy = require('express')();

let mailer = null;
let logger = null;

// configuration integrity check
if (!config.googleAnalytics || !config.googleAnalytics.id) {
  console.warn(c.yellow('[ℹ] Missing Google Analytics account ID.'));
  console.log('   Google Analytics is required.');

  process.exit(1);
}

if (!config.log || !config.log.filename) {
  console.warn(c.yellow('[ℹ] Missing Logger configuration.'));
  console.log('   Logger configuration is required.');

  process.exit(1);
}

if (!config.mail || !config.mail.params || !config.mail.recipients) {
  console.warn(c.yellow('[ℹ] Missing email config.'));
  console.log('    Email configuration is required.');

  process.exit(1);
}


// initialize services
console.log('[ℹ] Initializing Logger...');

try {
  logger = new (winston.Logger)({
    transports: [
      new (winston.transports.File)({ filename: config.log.filename })
    ]
  });
  console.log(c.green('[✔] Logger successfully initialized.'));
} catch (err) {
  console.warn(c.yellow('[✖] Unable to initialize Logger', err.message));

  process.exit(1);
}


console.log('[ℹ] Initializing Mailer...');

mailer = nodemailer.createTransport(config.mail.params);
mailer.use('compile', hbs({
  viewEngine: '',
  viewPath: './'
}));
mailer.verify()
  .then(() => {
    console.log(c.green('[✔] Mailer successfully initialized.'));
  })
  .catch(err => {
    console.warn(c.yellow('[✖] Unable to initialize Mailer', err));

    process.exit(1);
  });



// start web server
console.log(c.bold('[ℹ] Starting Kuzzle Analytics proxy...'));

proxy.use(bodyParser.json());

// health check
proxy.get('/', (request, result) => result.send('OK'));

proxy.post('/', (request, result) => {
  // handle post request
  if (!request.body) {
    console.error(c.red('[✖] Unable to JSON-parse the request body'));
    return result.sendStatus(403);
  }

  if (!request.body.uid || request.body.uid.length !== 64) {
    console.error(c.red('[✖] Request must contains a uid'));
    console.log(request.body)
    return result.sendStatus(403);
  }

  if (!request.body.type) {
    console.error(c.red('[✖] Request must contains a type'));
    return result.sendStatus(403);
  }

  // here we seed a uuid to simulate a "session"
  let userId = uuid(request.body.uid.substring(0, 32), request.body.uid.substring(32));
  let sessionAnalytics = ua(config.googleAnalytics.id, userId, {strictCidFormat: false});

  let gaParams = {
    uip: getIp(request),
    cid: userId,
    ec: request.body.type,
    ea: `os: ${request.body.os}, ip: ${getIp(request)}`
  };

  switch (request.body.type) {
    case 'pulled-latest-containers':

      sessionAnalytics.set("dimension1", request.body.os);
      sessionAnalytics.set("dimension2", request.body.purpose);

      // send an email when user has accepted to transfert personnal data
      mailer.sendMail({
        from: 'analytics@kuzzle.io',
        to: config.mail.recipients,
        subject: '[Setup.sh Analytics] Someone installed Kuzzle!',
        template: 'installed',
        context: {
          email: request.body.email,
          os: request.body.os,
          purpose: request.body.purpose,
          name: request.body.name,
          ip: getIp(request)
        }
      })
      .then(() => {
        console.log(`[ℹ] Successfull installation reported via mail (${config.mail.recipients})`);
      })
      .catch((err) => {
        console.error(c.red('[✖] Unable to report successfull installation via mail', err.message));
      });
      break;
  }

  sessionAnalytics.event(gaParams).send();
  logger.log('info', request.body.purpose, request.body);

  return result.sendStatus(200);
});

proxy.listen(config.port, () => {
  console.log(c.bold.green(`[✔] Kuzzle Analytics proxy listening on port ${config.port}`));
});

const getIp = (req) => {
  return req.headers['x-forwarded-for'] || req.connection.remoteAddress;
};
