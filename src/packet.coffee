
_ = require("lodash")
Base = require("./base")
dgram = require("dgram")

#private
module.exports = class Packet extends Base

  name: "Packet"

  constructor: (@data, @rinfo) ->

    if @data instanceof Buffer
      @data = @data.toString()

    if _.isString @data
      try
        @data = JSON.parse @data
      catch e
        @err "Invalid data: #{e}"

    @dest = @data.dest if @data.dest

    @src =
      host: @rinfo?.address
      port: @rinfo?.port

  #send 1 packet
  send: (callback) ->
    @data.src =
      host: @data.host
      port: @data.port

    @log "send to #{@dest.port}"

    str = JSON.stringify @data
    message = new Buffer str
    client = dgram.createSocket("udp4")
    client.on 'message', => @log "on message", arguments
    client.send message, 0, message.length, @dest.port, @dest.host, (err, bytes) =>
      # @log "sent #{bytes}"
      client.close()


  #recieve 1 packet
  recieve: (port, callback) ->
    # server = dgram.createSocket("udp4")
    # server.on "message", callback
    # server.on "listening", ->
    #   address = server.address()
    #   console.log "Server listening for updates on: " + address.port
    # server.bind port
