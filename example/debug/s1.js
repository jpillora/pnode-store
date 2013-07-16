var eg = require('../eg');

var store = eg.create();
var foo = store.bucket('foo');

eg.after(100, function() {
  foo.set('A', eg.val(50)+7);
});
eg.after(200, function() {
  foo.set('B', eg.val(50)+7);
});
eg.after(400, function() {
  foo.set('C', eg.val(50)+7);
});
eg.after(600, function() {
  foo.del('B');
});
eg.after(700, function() {
  foo.set('A', 3);
});
