
_ = require("lodash")
async = require("async")
Base = require("./base")
helper = require("./helper")
upnode = require('upnode')

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
    @conneted = false
    @ready = false
    #client dnode connection
    @log "connecting..."

    #provide to server
    up = upnode @makeApi()

    @upnode = up.connect @port, @host
    @upnode.on "up", (remote) =>
      numRetries = 0
      @initRemote remote
      @log "connected"
      @conneted = true

    @upnode.on "down", =>
      @log "disconnected"
      @conneted = false

    @upnode.on "reconnect", =>
      numRetries++
      @log "retrying... (##{numRetries})"
      if numRetries is MAX_RETRIES
        @destroy()

    # helper.tap @upnode, 'emit', => @log ">> emit", arguments[0]

  destroy: ->
    @log "destroy"
    @internal?.d.end()
    @upnode.close()
    @server.remove @id

  #interface for server
  makeApi: ->
    clients: _.keys @server.clients
    source: @server.id
    buckets: @store.buckets.keys()

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
    rem.clients.forEach @server.add

    #compare server time
    async.times 10, (n, next) =>
      clientT = Date.now()
      rem.time (serverT) =>
        trip = Math.round((Date.now() - clientT)/2)
        diff = clientT - (serverT + trip)
        next null, diff
    , (err, results) =>

      return @log "remote error", err if err
      sum = results.reduce ((s,n)->s+n),0
      @tDiff = Math.round sum/results.length
      @ready = true

    null

  toString: ->
    "#{@server} #{Base::toString.call @}"
