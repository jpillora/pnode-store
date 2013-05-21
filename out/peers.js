// Generated by CoffeeScript 1.6.2
var Base, Peer, Peers, upnode, _,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

_ = require("lodash");

Base = require("./base");

upnode = require('upnode');

Peer = (function(_super) {
  __extends(Peer, _super);

  Peer.prototype.name = "Peer";

  function Peer(peers, dest) {
    var m,
      _this = this;

    this.peers = peers;
    m = String(dest).match(/^((.+):)?(\d+)$/);
    if (!m) {
      this.err("Invalid destination: '" + dest + "'");
    }
    this.host = m[2] || this.peers.store.host;
    this.port = parseInt(m[3], 10);
    this.log(" <<NEW>> peer " + this.host + ":" + this.port);
    this.wrapper = {
      src: this.peers.id()
    };
    this.client = upnode.connect(this.port);
    this.client.on("up", function(remote) {
      return _this.peers.send({
        setup: _this.id()
      });
    });
    this.client.on("down", function() {
      return _this.log("lost connection to " + _this.port);
    });
    this.client.on("reconnect", function() {});
  }

  Peer.prototype.id = function() {
    return (this.host ? this.host + ':' : '') + this.port;
  };

  Peer.prototype.send = function(data) {
    var _this = this;

    return this.client(function(remote) {
      return remote.handle(_.extend({
        data: data,
        peers: _this.peers.ids()
      }, _this.wrapper));
    });
  };

  Peer.prototype.toString = function() {
    return "" + this.peers + this.name + ": ";
  };

  return Peer;

})(Base);

module.exports = Peers = (function(_super) {
  __extends(Peers, _super);

  Peers.prototype.name = "Peers";

  function Peers(store, peers) {
    var setup,
      _this = this;

    this.store = store;
    if (peers == null) {
      peers = [];
    }
    this.log("create peers");
    _.bindAll(this);
    this.array = [];
    _.each(peers, this.add);
    store = this.store;
    setup = this.setup;
    this.server = upnode(function() {
      return setup(this);
    });
    this.server.listen(this.store.port, function() {
      _this.spread();
      return _this.log("peer server listening on " + _this.store.port);
    });
  }

  Peers.prototype.setup = function(server) {
    return server.handle = this.handle;
  };

  Peers.prototype.spread = function() {
    var _this = this;

    return setTimeout(function() {
      return _this.send({
        setup: _this.id()
      });
    }, 1000);
  };

  Peers.prototype.add = function(destination) {
    return this.array.push(new Peer(this, destination));
  };

  Peers.prototype.handle = function(wrapper) {
    var data, id, p, peers, _i, _len;

    data = wrapper.data;
    if (data.method === 'set') {
      this.store._set(data.sid, data.sess);
    } else if (data.method === 'destroy') {
      this.store._destroy(data.sid);
    }
    peers = wrapper.peers || [];
    for (_i = 0, _len = peers.length; _i < _len; _i++) {
      p = peers[_i];
      if (!this.hasPeer(p)) {
        this.add(p);
      }
    }
    id = wrapper.src;
    if (id && !this.hasPeer(id)) {
      return this.add(id);
    }
  };

  Peers.prototype.hasPeer = function(id) {
    if (this.id() === id) {
      return true;
    }
    return __indexOf.call(this.ids(), id) >= 0;
  };

  Peers.prototype.id = function() {
    return (this.store.host ? this.store.host + ':' : '') + this.store.port;
  };

  Peers.prototype.ids = function() {
    return this.array.map(function(p) {
      return p.id();
    });
  };

  Peers.prototype.send = function(data) {
    var p, _i, _len, _ref, _results;

    _ref = this.array;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      p = _ref[_i];
      _results.push(p.send(data));
    }
    return _results;
  };

  return Peers;

})(Base);
