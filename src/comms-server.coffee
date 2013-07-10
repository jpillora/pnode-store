
_ = require("underscore")
Base = require("./base")
helper = require("./helper")
upnode = require('upnode')

#private
class Peer extends Base
  name: "Peer"
  constructor: (@comms, dest) ->

    {@host, @port} = helper.parseDestination dest

    unless @host and @port
      @err "Invalid destination: '#{dest}'"
      return null

    @destination = @id = "#{@host}:#{@port}"

    @log "create"

    @wrapper =
      src: @comms.source

    #list of buckets
    @buckets = {}

    #client dnode connection
    @client = upnode.connect @port, @host
    @client.on "up", (remote) =>
      @log "connected"
      @comms.add remote.source
      @peers.send {setup:@id()}

    @client.on "down", =>
      @log "disconnected"

    @client.on "reconnect", =>
      @log "retrying..."

  send: (data) ->
    @client (remote) =>
      remote.handle _.extend {
        data, peers: @peers.ids()
      }, @wrapper

#public
module.exports = class CommsServer extends Base

  name: "CommsServer"

  constructor: (@store, peers = []) ->
    @log "create"
    
    @host = helper.getIp()
    @port = @store.opts.port
    @source = @id = "#{@host}:#{@port}"

    _.bindAll @
    
    @array = []
    peers.forEach @add

    #build api
    api = _.pick @, 'handle', 'source'

    @server = upnode =>
      #give connection an api
      return api

    @server.listen @port, =>
      @spread()
      @log "listening on #{@port}"

  spread: ->
    setTimeout =>
      @send {setup:@id()}
    , 1000

  add: (destination) ->
    @array.push new Peer(@, destination)

  #send all
  send: (data) ->
    for p in @array
      p.send data


  handle: (wrapper) ->

    data = wrapper.data
    if data.method is 'set'
      @store._set data.sid, data.sess
    else if data.method is 'destroy'
      @store._destroy data.sid

    peers = wrapper.peers or []
    for p in peers
      if not @hasPeer p
        @add p

    id = wrapper.src
    if id and not @hasPeer id
      @add id

  hasPeer: (id) ->
    return true if @id() is id
    id in @ids()

  id: ->
    (if @store.host then @store.host + ':' else '')+@store.port

  ids: ->
    @array.map (p) -> p.id()




