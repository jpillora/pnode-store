
var express = require('express'),
    P2PSessionStore = require('../');

function createServer(port, peerPort, peers, callback) {

  var app = express();

  sessionOpts = {secret: 'secr3t'};

  if(peerPort && peers)
    sessionOpts.store = new P2PSessionStore({
      port: peerPort,
      peers: peers
    });

  app.use(express.session(sessionOpts));

  app.get('/', function(req, res) {
    res.send("hello world");
  });

  console.log("HTTP on " + port + " and UDP on " + peerPort);
  return app.listen(port, callback);
}

module.exports = createServer;