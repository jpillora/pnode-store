
_ = require "lodash" 
async = require "async" 
Base = require "./base" 
helper = require "./helper" 
upnode = require 'upnode' 
util = require "util"

MAX_RETRIES = 3

module.exports = class CommsClient extends Base
  name: "Client"
  constructor: (@server, @host, @port) ->
    #vars
    @store = @server.store
    @destination = @id = "#{@host}:#{@port}"
    numRetries = 0
    @tDiff = 0
    #will contain upnode proxies
    @remote = {}
    #states
    @connected = false
    @ready = false
    #client dnode connection
    @log "connecting..."

    #provide to server
    up = upnode @makeApi()

    @upnode = up.connect @port, @host

    @upnode.on "remote", (remote, dnode) =>

      dnode.on 'error', (e) =>
        @err "dnode error: #{e.stack}"

      numRetries = 0
      @initRemote remote
      @connected = true
      @log "connected"
      @emit "connected"

    @upnode.on "down", =>
      @connected = false
      @ready = false
      @log "disconnected"
      @emit "disconnected"

    @upnode.on "reconnect", =>
      numRetries++
      @log "retrying... (##{numRetries})"
      if numRetries is MAX_RETRIES
        @destroy()

    # helper.tap @upnode, 'emit', => @log ">> emit", arguments[0]

  destroy: ->
    @log "destroy"
    @emit "destroy"
    @internal?.dnode.end()
    @upnode.close()

  #interface for server
  makeApi: ->
    source: @server.id
    peers: _.keys @server.clients
    buckets: @store.buckets.valMap (b) -> b.times()

  makeUpnodeProxy: (name) ->
    return =>
      args = Array::slice.call arguments
      @upnode (rem) =>
        rem[name].apply rem, args
      true

  initRemote: (rem) ->

    @remote = {}
    #create upnode proxies to each function
    _.each rem, (fn, name) =>
      return if typeof fn isnt 'function'
      @remote[name] = @makeUpnodeProxy name

    #add peers
    rem.clients.forEach @server.addClient

    #compare server time
    async.timesSeries 3, (n, next) =>
      clientT = Date.now()
      rem.time (serverT) =>
        trip = Math.round((Date.now() - clientT)/2)
        diff = (serverT + trip) - clientT
        next null, diff

    , (err, results) =>
      return @log "remote error", err if err
      sum = results.reduce ((s,n)->s+n),0
      @tDiff = Math.round sum/results.length
      @ready = true
      @log "avg rtt: #{@tDiff}"
      @emit 'ready'

    null

  toString: ->
    "#{@server} #{Base::toString.call @}"
