var eg = require('../eg');

global.store = eg.create();

// if(eg.val(10) < 5)
setTimeout(function() {
  var foo = store.bucket('foo');
  foo.set('bar', eg.val(50)+7);
}, 1000 + eg.val(5000));


setTimeout(function() {
  require('repl').start({
    prompt: "",
    input: process.stdin,
    output: process.stdout,
    useGlobal: true
  });
}, 2000);