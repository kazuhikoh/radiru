const Rx = require('rxjs/Rx');
const axios = require('axios');

function index() {
  const url = 'http://www.nhk.or.jp/radioondemand/json/index/index.json';

  return Rx.Observable
    .fromPromise(
      axios.get(url)
    )
    .map(res => {
      return res.data
    });
}

module.exports = {
  index
};
