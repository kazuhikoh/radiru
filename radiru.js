#!/usr/bin/env node

const app = require('commander');
const api = require('./datasource/remote/radiru-api');

const download = require('./internal/download');

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

app
  .command('download <siteId> <cornerId> <filename>')
  .option('-n, --noaction', 'no action. print filenames to be saved.')
  .action((siteId, cornerId, filename, cmd) => {
    const exec = (cmd.noaction ? download.execWithoutAction : download.exec);
    exec(siteId, cornerId, filename).subscribe();
  });

app.parse(process.argv);
