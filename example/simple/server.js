var _ = require('lodash');
var PeerStore = require('../../');

var peers = process.argv.slice(2),
    port = Number(peers.shift());

if(!port) {
  console.log('no port');
  process.exit(1);
}

var store = new PeerStore({
  port: port,
  peers: peers
});

var foo = store.bucket('foo');

var randomValue = function(max) {
  return Math.floor(Math.random()*max);
};

var randoms = 500;
var addRandom = function() {
  if(randoms === 0)
    return setTimeout(check,2000);


  var key = PeerStore.helper.guid();
  var val = randomValue(1e10);
  foo.set(key, val, function(err) {
    if(err)
      return console.error("error setting: ", key);
    randoms--;
    setTimeout(addRandom, randomValue(10));
  });
};

var check = function() {
  console.log('check!');
  var client = store.server.clients[PeerStore.helper.getIp()+':12000'];
  if(!client) return process.exit(1);
  console.log('getall on ', client.id);

  store.buckets.get('foo').getAll(function(err, thisObj) {
    //get this bucket
    client.remote.getAll('foo', function(err, otherObj) {
      //get other bucket
      if(err) return console.log("!", err);
      // console.log(">>>", thisObj);
      // console.log(">>>", otherObj);
      console.log("stores match:", compare(thisObj, otherObj, 1000));
      process.exit(1);
    });
  });
};

var compare = function(A,B,size) {
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


setTimeout(addRandom,2000);