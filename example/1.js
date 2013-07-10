
var PeerStore = require('../');

var store1 = new PeerStore({
  port: 5000,
  peers: ['localhost:4000']
});

var store2 = new PeerStore({
  port: 4000
});

// store.bucket('data');

// store.set('foo', 42);

// var bars = store.create('bars');

// bars.get('');
