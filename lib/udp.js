
var dgram = require('dgram');

//public send
exports.send = function(dest, msg) {
  var m = String(dest).match(/^((.+):)?(\d+)$/);
  if(!m) throw new Error("Invalid destination: '" + dest + "'");
  var port = parseInt(m[3], 10);
  var host = m[2] || "localhost";
  var dgram = require('dgram');
  var message = new Buffer(msg);
  var client = dgram.createSocket("udp4");
  client.send(message, 0, message.length, port, host, function(err, bytes) {
    client.close();
  });
};

//public recieve
exports.recieve = function(port, callback) {
  var dgram = require("dgram");
  var server = dgram.createSocket("udp4");
  server.on("message", callback);
  server.on("listening", function () {
    var address = server.address();
    console.log("Server listening for updates on: " + address.port);
  });
  server.bind(port);
};

