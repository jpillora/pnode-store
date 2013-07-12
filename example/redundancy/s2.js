
var eg = require('../eg');

var store = null;

eg.after(1000, function() {
  store = eg.create(12000, [eg.helper.getIp()+':11000']);

  eg.every(1000, function() {
    store.set('s3-bang-'+eg.helper.guid(), '!');
  });
});
