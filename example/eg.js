//example handlers

var _ = require('lodash');
var PeerStore = require('../');

exports.create = function() {

  var peers = process.argv.slice(2),
      port = Number(peers.shift());

  if(!port) {
    console.log('no port');
    process.exit(1);
  }

  return new PeerStore({
    port: port,
    peers: peers
  });
};

exports.compare = function(A,B,size) {
  for(var a in A) {
    size--;
    if(A[a] !== B[a])
      return false;
    delete B[a];
  }
  for(var b in B)
    return false;
  if(size !== 0)
    return false;
  return true;
};

exports.val = function(max) {
  return Math.floor(Math.random()*max);
};

exports.helper = require('../').helper;