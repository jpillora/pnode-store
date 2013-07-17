var _ = require('lodash');
var PeerStore = require('../../');

//calculate stuff
var valueSize = 5;
var value = "";
while(valueSize--) value += "v";
var key = "my-key-";
var inserts = 0;
var receives = 0;
var batch = 5e3;

var store = new PeerStore({
  port: 37000,
  peers: ['172.18.0.99:38000']
});
var bucket1 = store.bucket('foo');

var other = new PeerStore({
  port: 38000,
  peers: ['172.18.0.99:37000']
});
var bucket2 = other.bucket('foo');

setInterval(function insert() {
  var i = batch;
  while(i--) bucket1.set(key + (++inserts), value);
  console.log("inserted", inserts);
}, 100);

bucket2.on('set', function(k) {
  receives++;
});

setInterval(function() {
  console.log(receives);
  receives = 0;
}, 1000);



