const proc = require('child_process');
const util = require('util');
const Rx = require('rxjs/Rx');
const Multispinner = require('multispinner')

const api = require('../datasource/remote/radiru-api');

function findTargets(siteId, cornerId, filename) {
  return api.program(siteId, cornerId)
    .flatMap(it => {
      return Rx.Observable.combineLatest(
        Rx.Observable.of(it),
        Rx.Observable.from(it.detail_list),
        (program, detail) => {
          return {program, detail};
        });
    })
    .flatMap(it => {
      return Rx.Observable.combineLatest(
          Rx.Observable.of(it.program),
          Rx.Observable.of(it.detail),
          Rx.Observable.from(it.detail.file_list),
          (program, detail, file) => {
            return {program, detail, file};
          }
      );
    })
    .flatMap(it => {
      // variables that 'filename' template refer.
      // ex) filename : ${program.site_id}.mp3
      const {program, detail, file} = it;
      const out = genFilename(
          filename,
          program, detail, file
      );

      const m3u8 = it.file.file_name;

      return Rx.Observable.of({
        in:  m3u8,
        out: out
      });
    });

}

function execWithoutAction(siteId, cornerId, filename) {
  return findTargets(siteId, cornerId, filename)
    .do(it => {
      console.log(it.out);
    });
}
 
function exec(siteId, cornerId, filename) {
  const procexec = util.promisify(proc.exec);
  const errors = [];

  return findTargets(siteId, cornerId, filename)
    .reduce((prev, next) => {
      prev.push(next);
      return prev;
    }, [])
    .flatMap(targets => {
      const files = targets.map(it => it.out);
   
      // filename is duplicated => no action
      const dupFiles = files.filter((id, i) => files.indexOf(id) != i);
      if (dupFiles.length > 0) {
        console.error('Duplicated filename exists! Use variables for filename. (e.g. "${file.file_id}.mp3")');
        files.forEach((it, i) => {
          const x = dupFiles.includes(it) ? "x" : " "; 
          console.error(`${x} ${it}`);
        });
   
        return Rx.Observable.empty();
      }

      return Rx.Observable.from(targets);
    })
    .flatMap(it => {
      // filename is already exists => skip
      const cmdTestNone = `[ ! -e "${it.out}" ]`;
      return Rx.Observable
        .fromPromise(procexec(cmdTestNone))
        .catch(err => {
          console.log(`File already exists: "${it.out}"`);
          return Rx.Observable.empty();
        })
        .flatMap(output => {
          return Rx.Observable.of(it);
        });
    })
    .reduce((prev, next) => {
      prev.push(next);
      return prev;
    }, [])
    .flatMap(targets => {
      // show progress
      const ids = targets.map(it => it.out);
      const progress = new Multispinner(ids);

      progress.on('done', () => {
        if (errors.length > 0) {
          errors.forEach(err => console.error(err));
        }
      });

      return Rx.Observable
        .from(targets)
        .flatMap(it => {
          const id = it.out;
          const cmdDownload = `ffmpeg -n -i ${it.in} "${it.out}"`;

          return Rx.Observable
            .fromPromise(procexec(cmdDownload))
            .map(it => {
              progress.success(id);
              return it;
            })
            .catch(err => {
              progress.error(id);
              errors.push(err);
              return Rx.Observable.of(it);
            });
        });
    });
}

function genFilename(template, program, detail, file) {
  return eval('`' + template + '`');
}

module.exports = {
  exec,
  execWithoutAction,
};
