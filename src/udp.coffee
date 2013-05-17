dgram = require("dgram")

#public send
exports.send = (host, port, msg) ->
  dgram = require("dgram")
  message = new Buffer(msg)
  client = dgram.createSocket("udp4")
  client.send message, 0, message.length, port, host, (err, bytes) ->
    console.log client
    client.close()

#public recieve
exports.recieve = (port, callback) ->
  dgram = require("dgram")
  server = dgram.createSocket("udp4")
  server.on "message", callback
  server.on "listening", ->
    address = server.address()
    console.log "Server listening for updates on: " + address.port

  server.bind port