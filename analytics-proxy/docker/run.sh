#!/bin/bash

cd /var/app
npm install
pm2 start index.js
pm2 logs
