
_ = require("lodash")
async = require("async")
Base = require("./base")
helper = require("./helper")
upnode = require('upnode')

MAX_RETRIES = 5

module.exports = class CommsClient extends Base
  name: "CommsClient"
  constructor: (@comms, @host, @port) ->
    #vars
    @store = comms.store
    @destination = @id = "#{@host}:#{@port}"
    numRetries = 0
    @tDiff = 0

    #bucket set - map to booleans
    # whether client has a given bucket
    @buckets = {}
    #will contain upnode proxies
    @remote = {}

    #states
    @conneted = false
    @ready = false

    #client dnode connection
    @log "connecting..."

    #provide to server
    up = upnode @makeApi()

    @client = up.connect @port, @host
    @client.on "up", (remote) =>
      numRetries = 0
      @initRemote remote
      @log "connected"
      @conneted = true

    @client.on "down", =>
      @log "disconnected"
      @conneted = false

    @client.on "reconnect", =>
      numRetries++
      @log "retrying... (##{numRetries})"
      if numRetries is MAX_RETRIES
        @client.close()
        @comms.remove @id

  checkBucket: (name, times, callback) =>
    @log "check bucket: #{name} [#{times.t0}:#{times.tN}]"
    @buckets[name] = true
    callback(null) if callback

  #interface for server
  makeApi: ->
    peers: _.keys @comms.peers
    source: @comms.id
    pingBucket: @checkBucket

  makeUpnodeProxy: (name) ->
    return =>
      args = Array::slice.call arguments
      @client (rem) =>
        rem[name].apply rem, args
      true

  initRemote: (remote) ->
    @remote = {}
    #create upnode proxies to each function
    _.each remote, (fn, name) =>
      return if typeof fn isnt 'function'
      @remote[name] = @makeUpnodeProxy name

    #compare server time
    async.times 10, (n, next) =>
      clientT = Date.now()
      remote.time (serverT) =>
        trip = Math.round((Date.now() - clientT)/2)
        diff = clientT - (serverT + trip)
        next null, diff
    , (err, results) =>

      return @log "remote error", err if err
      sum = results.reduce ((s,n)->s+n),0
      @tDiff = Math.round sum/results.length

      #add and check all buckets
      for name, times of remote.buckets
        @checkBucket name, times

      @ready = true

    null

  toString: ->
    "#{@comms} #{Base::toString.call @}"
