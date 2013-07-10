
_ = require("lodash")
Base = require("./base")
helper = require("./helper")
CommsClient = require("./comms-client")
upnode = require('upnode')
async = require('async')

#public - reciever
module.exports = class CommsServer extends Base

  name: "CommsServer"

  constructor: (@store) ->
    
    @host = helper.getIp()
    @port = @store.opts.port
    @id = "#{@host}:#{@port}"

    @log "create"

    _.bindAll @

    #clients
    @clients = {}
    @store.opts.peers?.forEach @add

    #provide to client
    #api data
    @api = source: @id
    #api methods
    for name, fn of @apiMethods
      @api[name] = fn.bind @

    #give connection the api
    @server = upnode (remote, d) =>
      #when a client connects to us
      d.on 'remote', =>
        @add remote.source
        remote.peers.forEach @add
        @store.buckets.on 'set', remote.addBucket

      #update bucket set
      @api.initBuckets = @store.buckets.keys()
      return @api

    @server.listen @port, =>
      @log "listening..."

    #forceful kill of the server
    @server.on 'end', =>
      @log "unlistening..."
      for dest, peer of @clients
        peer.client.close()

  add: (dest) ->
    if dest is @id or @clients[dest]
      # @log "Peer at '#{dest}' already exists"
      return false

    {host, port} = helper.parseDestination dest

    unless host and port
      @log "Invalid destination '#{dest}'"
      return false

    @clients[dest] = new CommsClient(@, host, port)
    # @log "added: '#{dest}' (##{_.keys(@clients).length})"
    true

  remove: (dest) ->
    return unless @clients[dest]
    delete @clients[dest]
    @log "removed: '#{dest}'"

  #broadcast set
  set: (bucketName, key, value, callback) ->
    sets = []
    _.each @clients, (client, dest) ->
      return unless client.buckets[bucketName]
      sets.push (cb) -> client.remote.set(bucketName, key, value, cb)
    async.parallel sets, callback

  #broadcast delete
  del: (bucketName, key, callback) ->
    dels = []
    _.each @clients, (client, dest) ->
      return unless client.buckets[bucketName]
      dels.push (cb) -> client.remote.del(bucketName, key, cb)
    async.parallel dels, callback

  #expose methods to client
  #clients directly set and delete! (do not trigger further broadcasts)
  apiMethods:

    getAll: (bucketName, callback) ->
      bucket = @store.buckets.get bucketName
      unless bucket
        return callback "has no bucket: #{bucketName}"
      unless bucket.getAll
        return callback "has no getAll"

      bucket.getAll callback
      
    #execute an operation on a given bucket
    set: (bucketName, key, val, callback) ->
      bucket = @store.buckets.get bucketName
      unless bucket
        return callback "has no bucket: #{bucketName}"
      bucket.backendSet key, val, callback

    del: (bucketName, key, callback) ->
      bucket = @store.buckets.get bucketName
      unless bucket
        return callback "has no bucket: #{bucketName}"
      bucket.backendDel key, callback



