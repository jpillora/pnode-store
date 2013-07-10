
_ = require("lodash")
Base = require("./base")
helper = require("./helper")
upnode = require('upnode')

MAX_RETRYS = 5

#private - sender
module.exports = class CommsClient extends Base
  name: "CommsClient"
  constructor: (@comms, @host, @port) ->
    #vars
    @store = comms.store
    @destination = @id = "#{@host}:#{@port}"

    #bucket set
    @buckets = {}

    #client dnode connection
    @log "connecting..."

    #provide to server
    up = upnode
      peers: _.keys @comms.peers
      source: @comms.id
      addBucket: (name) =>
        @log "add bucket: #{name}"
        @buckets[name] = true

    numRetries = 0

    #will contain upnode proxies
    @remote = {}

    @client = up.connect @port, @host
    @client.on "up", (remote) =>
      numRetries = 0
      @log "connected"

      #set bucket set
      @buckets = {}
      for bucket in remote.initBuckets
        @buckets[bucket] = true

      #special upnode methods
      for name, fn of remote
        continue if typeof fn isnt 'function'
        @remote[name] = @makeRemoteFn name

    @client.on "down", =>
      @log "disconnected"

    @client.on "reconnect", =>
      numRetries++
      @log "retrying... (##{numRetries})"
      if numRetries is MAX_RETRYS
        @client.close()
        @comms.remove @id

  makeRemoteFn: (name) ->
    return =>
      args = Array::slice.call arguments
      @client (remote) =>
        remote[name].apply remote, args

  toString: ->
    "#{@comms} #{Base::toString.call @}"
