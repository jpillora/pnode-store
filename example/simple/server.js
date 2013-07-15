
var PeerStore = require("../../");
var peers = process.argv.slice(2);
var port = Number(peers.shift());

if(!port) {
  console.log('no port');
  process.exit(1);
}

var store = new PeerStore({
  port: port,
  peers: peers
});