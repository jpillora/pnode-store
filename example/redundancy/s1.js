
var eg = require('../eg');

var store = eg.create(11000, []);

eg.after(5000, function() {
  console.log("store.destroy...");
  store.destroy();
});