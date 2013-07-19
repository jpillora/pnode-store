
var PeerStore = require("../../");
var peers = process.argv.slice(2);
var port = Number(peers.shift());

var store = new PeerStore({
  port: port,
  peers: peers
});

store.set('foo',42);