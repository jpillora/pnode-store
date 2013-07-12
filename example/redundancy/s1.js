
var eg = require('../eg');

var store = eg.create(11000, []);

eg.after(10000, function() {
  console.log("store.destroy...");
  store.destroy();
});