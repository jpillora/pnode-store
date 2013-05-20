
_ = require("lodash")
Base = require("./base")
upnode = require('upnode')

#private
class Peer extends Base
  name: "Peer "
  constructor: (@store, dest) ->
    m = String(dest).match(/^((.+):)?(\d+)$/)
    @err "Invalid destination: '#{dest}'" unless m
    @host = m[2] or "localhost"
    @port = parseInt(m[3], 10)
    @log "create #{@host}:#{@port}"

    #client dnode connection
    @client = upnode.connect @port
    @client.on "up", (remote) =>
      @log "connected to #{@port}"
      @send {hello:'world'}

    @client.on "down", =>
      @log "lost connection to #{@port}"

    @client.on "reconnect", =>
      @log "trying #{@port}..."

  send: (args) ->
    method = args.shift()
    args.push (t) => @log "t: #{t}"
    @client (remote) =>
      remote[method].apply remote, args

#public
module.exports = class Peers extends Base
  name: "Peers"
  constructor: (@store, peers = []) ->
    @log "create peers"
    _.bindAll @
    @peers = []
    _.each peers, @add

    store = @store
    @server = upnode (client, conn) ->
      this.set = store._set
      this.destory = store._destroy

    @server.listen @store.port
    @log "dnode server listening on #{@store.port}"

  add: (destination) ->
    @peers.push new Peer(@store, destination)

  #setAll
  send: ->
    args = _.toArray arguments
    @peers.forEach (p) -> p.send args




