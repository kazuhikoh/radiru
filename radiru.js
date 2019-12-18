#!/usr/bin/env node

const app = require('commander');
const api = require('./datasource/remote/radiru-api');

app
  .version('1.0.0');

app
  .command('index')
  .option('-s, --search <name>', 'search program name')
  .action((cmd) => {
    api.index()
      .filter(x => {
        return (!cmd.search || x.program_name.includes(cmd.search));
      })
      .subscribe(x => {
        console.log(x);
      });
  });

app
  .command('program <siteId> <cornerId>')
  .action((siteId, cornerId) => {
    api.program(siteId, cornerId)
      .subscribe(it => {
        console.log(JSON.stringify(it, null, '\t'));
      });
  });

app.parse(process.argv);
