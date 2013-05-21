
_ = require("lodash")
Base = require("./base")
upnode = require('upnode')

#private
class Peer extends Base
  name: "Peer"
  constructor: (@peers, dest) ->
    m = String(dest).match(/^((.+):)?(\d+)$/)
    @err "Invalid destination: '#{dest}'" unless m
    @host = m[2] or @peers.store.host
    @port = parseInt(m[3], 10)
    @log " <<NEW>> peer #{@host}:#{@port}"

    @wrapper =
      src: @peers.id()

    #client dnode connection
    @client = upnode.connect @port
    @client.on "up", (remote) =>
      # @log "connected to #{@port}"
      @peers.send {setup:@id()}

    @client.on "down", =>
      @log "lost connection to #{@port}"

    @client.on "reconnect", =>
      # @log "trying #{@port}..."

  id: ->
    (if @host then @host + ':' else '')+@port

  send: (data) ->
    @client (remote) =>
      remote.handle _.extend {
        data, peers: @peers.ids()
      }, @wrapper

  toString: ->
    "#{@peers}#{@name}: "

#public
module.exports = class Peers extends Base
  name: "Peers"
  constructor: (@store, peers = []) ->
    @log "create peers"
    _.bindAll @
    @array = []
    _.each peers, @add

    store = @store
    setup = @setup
    @server = upnode -> setup this
    @server.listen @store.port, =>
      @spread()
      @log "peer server listening on #{@store.port}"

  setup: (server) ->
    server.handle = @handle

  spread: ->
    setTimeout =>
      @send {setup:@id()}
    , 1000

  add: (destination) ->
    @array.push new Peer(@, destination)

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

  #setAll
  send: (data) ->
    for p in @array
      p.send data




