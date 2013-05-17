
// Use with express like so:
//
// app.use(express.session({
//   store: new P2PSessionStore(),
//   secret: 'secret'
// }));

var connect = require('connect');
var udp = require('./udp');
var _ = require('lodash');
var difflet = require('difflet');

//Base Store Class
var Store = connect.session.Store;

//Constructor
function MyStore(options) {
  if(!options)
    this.err("Must specify options");

  //super
  Store.call(this, options);

  if(!options.port)
    this.err("Must specify a port");

  this.port = options.port;
  this.peers = options.peers || [];
  this.sessions = {};
  this.lasts = {};

  udp.recieve(this.port, this.handle.bind(this));
}

//Inherit Base Store Class
MyStore.prototype = Object.create(Store.prototype, {
  constructor: { value: MyStore }
});

//Propogate to peers
MyStore.prototype.propogate = function(data) {
  //add peers
  var thisPort = this.port;
  var pid = guid();

  data.peers = this.peers.concat(thisPort);

  var str = JSON.stringify(data);

  console.log("propogate '%s':'%s' to [%s]", data.method, data.args[0], this.peers.join(','));

  this.peers.forEach(function(p) {
    if(p === thisPort) return;
    udp.send(p, str);
  });

};



//Handle command from peer
MyStore.prototype.handle = function(str, rinfo) {
  var data = JSON.parse(str);

  //add peers
  if(data.method && data.args) {
    this.peers = _.union(this.peers, data.peers);
    if(data.method && data.args)
      this[data.method].apply(this, data.args);
  } else {

  }



};


MyStore.prototype.sendPacket =





//Get session = cookie id, callback(err,obj)
MyStore.prototype.get = function(sid, fn) {
  console.log("get '%s'", sid);
  fn(null, this.sessions[sid]);
};

//Set session = cookie id, session object, callback(err)
MyStore.prototype.set = function(sid, sess, fn) {

  sess = { user: sess.user };

  if(sess.user)
    console.log("set '%s'", sid);

  this.sessions[sid] = sess;

  //propogations have no callback
  if(!fn) return;

  //send updates

  console.log(this.lasts[sid]);

  if(sess.user && !_.isEqual(sess, this.lasts[sid])) {
    console.log(difflet.compare(sess, this.lasts[sid]))
    this.propogate({ method:'set', args: [sid, sess] });
    // console.log(sess);
    this.lasts[sid] = sess;
  }

  fn(null);
};

//Delete session = cookie id, callback(err)
MyStore.prototype.destroy = function(sid, fn) {
  console.log("delete '%s'", sid);
  delete this.sessions[sid];
  if(!fn) return;
  this.propogate({ method:'destroy', args: [sid] });
  fn(null);
};

MyStore.prototype.err = function(str) {
  throw new Error("P2PSessionStore: " + str);
};

module.exports = MyStore;


//helpers
function isArray(val) {
  return Object.prototype.toString.call(val) === '[object Array]';
}
function guid() {
  return (Math.random()*Math.pow(2,32)).toString(16);
}
