
var createServer = require('./create-server');

var peers = process.argv.slice(2),
    port = Number(peers.shift()),
    peerPort = Number(peers.shift());

createServer(port, peerPort, peers);