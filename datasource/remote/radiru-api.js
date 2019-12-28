const Rx = require('rxjs/Rx');
const axios = require('axios');

function index() {
  const url = 'http://www.nhk.or.jp/radioondemand/json/index_v3/index.json';

  return Rx.Observable
    .fromPromise(
      axios.get(url)
    )
    .map(res => {
      return res.data;
    })
    .flatMap(data => {
      return Rx.Observable.from(data.data_list);
    });
}

function program(siteId, cornerId) {
  const url = `http://www.nhk.or.jp/radioondemand/json/${siteId}/bangumi_${siteId}_${cornerId}.json`;

  return Rx.Observable
    .fromPromise(
      axios.get(url)
    )
    .map(res => {
      return res.data;
    })
    .map(data => {
      return data.main;
    });
}

module.exports = {
  index,
  program,
};
