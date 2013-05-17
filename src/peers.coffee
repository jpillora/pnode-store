
_ = require("lodash")
Base = require("./base")
Packet = require("./packet")
udp = require("./udp")

#private
class Peer extends Base
  name: "Peer "
  constructor: (@store, dest) ->
    m = String(dest).match(/^((.+):)?(\d+)$/)
    @err "Invalid destination: '#{dest}'" unless m
    @host = m[2] or "localhost"
    @port = parseInt(m[3], 10)
    @log "create #{@host}:#{@port}"

  #pass this peer some data
  pass: (data) ->
    data.dest = { @host, @port }
    packet = new Packet(data)
    packet.send()

#public
module.exports = class Peers extends Base
  name: "Peers"
  constructor: (@store, peers = []) ->
    @log "create peers"
    _.bindAll @
    @peers = []
    _.each peers, @add

    udp.recieve @store.port, @handle

  add: (destination) ->
    @peers.push new Peer(@store, destination)

  pass: (data) ->
    @peers.forEach (p) -> p.pass data

  handle: (str, rinfo) ->
    packet = new Packet str, rinfo
    data = packet.data

    @log "recieved data from: #{packet.src.port}"

    if data.action is 'set'
      @store.setSession data.sid, data.sess
