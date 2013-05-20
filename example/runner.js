
var createServer = require('./create-server');

var peers = process.argv.slice(2).map(Number),
    port = peers.shift(),
    peerPort = peers.shift();

createServer(port, peerPort, peers);