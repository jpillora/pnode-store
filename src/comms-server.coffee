
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
        client = @add remote.source
        unless client
          @err "recieved connection from self..."

        client.clientRemote = remote
        remote.peers.forEach @add

      #dynamic api methods
      return @makeApi()

    @server.listen @port, =>
      @log "listening..."

    #forceful kill of the server
    @server.on 'end', =>
      @log "unlistening..."
      for dest, client of @clients
        client.client.close()

  add: (dest) ->
    return false if dest is @id
    return @clients[dest] if @clients[dest]

    {host, port} = helper.parseDestination dest

    unless host and port
      @log "Invalid destination '#{dest}'"
      return false

    return @clients[dest] = new CommsClient(@, host, port)

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

  #expose methods to client
  makeApi: ->
    api =
      source: @id
      buckets: {}
      time: (cb) =>
        cb Date.now()
      getBucket: (query, callback) =>
        callback null, @store.buckets.get(query)?.times()

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



