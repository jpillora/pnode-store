var fork = require('child_process').fork;

var s1 = fork('./server', [11000, '172.18.0.99:12000']);
var s2 = fork('./server', [12000]);
// var s3 = fork('./server', [13000, '172.18.0.99:12000']);

// setTimeout(function() {
//   console.log("====== START 2")
//   s2 = 
// }, 2000);

// setTimeout(function() {
//   console.log("====== KILL 2")
//   s2.kill();
// }, 4000);

// setTimeout(function() {
//   console.log("====== KILL 3")
//   s3.kill();
// }, 6000);