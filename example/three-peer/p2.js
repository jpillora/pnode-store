var pnode = require('../../../pnode');
var store = require('../../');
pnode.install(store);

var peer2 = pnode.peer({
  id: 'peer2',
  debug: false
});

peer2.bindTo('tcp://localhost:8000');

var peer2Store = peer2.store('foo');

setTimeout(function() {
  console.log('peer2 has:',peer2Store.object());
  process.exit(1);
}, 1000);
