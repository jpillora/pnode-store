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

var randoms = 10;
var addRandom = function() {
  randoms--;
  var key = PeerStore.helper.guid();
  var val = randomValue(1e10);
  foo.set(key, val, function(err) {
    if(err)
      return console.error("error setting: ", key);
    if(randoms > 0)
      setTimeout(addRandom, 100+randomValue(100));
    else
      setTimeout(check, 200);
  });
};

var check = function() {
  console.log('check!');

  var client = store.server.clients['172.18.0.99:12000'];
  if(!client) return;

  console.log('getall on ', client.id);

  client.remote.getAll(function(err, obj) {
    console.log("other: ", obj);

  });

};

setTimeout(addRandom,20000);