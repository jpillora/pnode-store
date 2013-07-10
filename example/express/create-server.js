
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

  app.use(express.bodyParser());
  app.use(express.cookieParser(false));
  app.use(express.session(sessionOpts));

  app.get('/', function(req, res) {
    res.send(req.session.user || 'anon');
  });
  app.get('/login', function(req, res) {
    req.session.user = { foo: "bar" };
    res.send("login!");
  });
  app.get('/logout', function(req, res) {
    req.session.destroy();
    res.send("logout!");
  });

  return app.listen(port, callback);
}

module.exports = createServer;