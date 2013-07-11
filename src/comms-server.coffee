
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

    _.bindAll @

    #clients
    @clients = {}
    @store.opts.peers?.forEach @add

    #give connection the api
    @server = upnode (remote, d) =>
      #when a client connects to us
      d.on 'remote', =>
        #add remote and all of it's peers
        @add remote.source
        remote.peers.forEach @add

      #dynamic api methods
      return @makeApi()

    @server.listen @port, =>
      @log "listening..."

    #forceful kill of the server
    @server.on 'end', =>
      @log "unlistening..."
      for dest, peer of @clients
        peer.client.close()

    #add to remotes bucket list when we change ours
    @store.buckets.on 'set', @broadcastNewBucket

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

  #broadcast - will call API methods on all relavant clients
  broadcast: (fnName, args, filter = -> true) ->
    callback = helper.getCallback args
    fns = []
    _.each @clients, (client, dest) ->
      return unless client.conneted and client.ready and filter client, dest
      fn = client.remote[fnName]
      fns.push (cb) -> fn.apply(client.remote, args.concat(cb))

    async.parallel fns, callback

  broadcastNewBucket: (name, bucket) =>
    gotBuckets = (err, bucketList) =>
      @log "found buckets: ", bucketList

    @log "searching for other '#{name}' buckets"
    @broadcast 'getBuckets', [name, gotBuckets]

  broadcastBucketOp: (fnName, args) =>
    @broadcast fnName, args, (client) ->
      return client.buckets[bucketName]

  #expose methods to client
  makeApi: ->
    api =
      source: @id
      buckets: {}
      time: (cb) =>
        cb Date.now()

      getBuckets: (query, callback) =>
        results = {}
        @store.buckets.each (name, bucket) ->
          if query is name
            results[name] = bucket.times()
        callback null, results

    #add each bucket's time stats
    @store.buckets.each (name, bucket) ->
      api.buckets[name] = bucket.times()

    # add particular bucket methods
    # calls are all to sent to the backend (do not trigger further broadcasts)
    ['getAll','get','set','del'].forEach (fnName) =>
      api[fnName] = =>
        args = helper.arr arguments
        callback = args[args.length-1]
        if typeof callback isnt 'function'
          @err "bucket: #{bucketName}: '#{fnName}': callback missing"

        bucketName = args.shift()
        bucket = @store.buckets.get bucketName
        unless bucket
          return callback "has no bucket: #{bucketName}"
        bucket.backendOp fnName, args

    return api



