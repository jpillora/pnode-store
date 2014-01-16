
var pnode = require('../../pnode');
var store = require('../');
pnode.install(store);

function watch(store) {
  store.on('set', function(path, value) {
    console.log('peer %s: set "%s" = %j   %j', store.peer.id, path, value, store.object());
  });
  store.on('del', function(path) {
    console.log('peer %s: del "%s"    %j', store.peer.id, path, store.object());
  });
}


//START SERVER
var peer1 = pnode.peer({
  id: 'peer-1',
  debug: false
});
peer1.bindOn('tcp://0.0.0.0:8000', function(){
  console.log('bound to all interfaces on port 8000');
});
var peer1Store = peer1.store('foo');
watch(peer1Store);

//START CLIENT 1
var peer3 = pnode.peer({
  id: 'peer-3',
  debug: false
});
var peer3Store = peer3.store('foo');
watch(peer3Store);

peer3.bindTo('tcp://localhost:8000');

peer1Store.set('s.t.u', 7);
peer1Store.set('a.b.c', 13);

var peer2;
var peer2Store;
//START CLIENT 1
peer2 = pnode.peer({
  id: 'peer-2',
  debug: false
});
peer2.bindTo('tcp://localhost:8000');


setTimeout(function() {
  peer2Store = peer2.store('foo');
  watch(peer2Store);
}, 500);

setTimeout(function() {
  peer1Store.set('x', {y:["z"]});
  // peer1Store.del('a.b');
}, 1000);

setTimeout(function() {
  console.log('peer-1 has:',peer1Store.object());
  console.log('peer-2 has:',peer2Store.object());
  console.log('peer-3 has:',peer3Store.object());
  process.exit(1);
}, 3000);
