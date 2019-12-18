#!/usr/bin/env node

const app = require('commander');
const api = require('./model/api');

app
  .version('1.0.0');

app
  .command('index')
  .action(() => {
    api.index().subscribe(x => {
      console.log(x);
    });
  });

app.parse(process.argv);
