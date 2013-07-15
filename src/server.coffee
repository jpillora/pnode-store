
_ = require("lodash")
Base = require("./base")
helper = require("./helper")
CommsClient = require("./client")
upnode = require('upnode')
async = require('async')

#public - reciever
module.exports = class CommsServer extends Base

  name: "Server"

  constructor: (@store) ->
    
    _.bindAll @
    @host = helper.getIp()
    @port = @store.opts.port
    @id = "#{@host}:#{@port}"

    #clients
    @clients = {}

    #give connection the api
    @upnodeDaemon = upnode (remote, dnode) =>

      client = null

      #when a client connects to us
      dnode.on 'remote', =>
        #add remote and all of it's peers
        client = @add remote.source
        unless client
          @err "recieved connection from self..."
        client.internal = {remote,dnode}

        remote.buckets.forEach (name) =>
          @store.buckets.get(name)?.ping(remote.source)

        #add peers
        remote.clients.forEach @add

      dnode.on 'error', (err) =>
        @log "connection error",err
        if client
          client.destroy()

      #dynamic api methods
      return @makeApi()

    @upnode = @upnodeDaemon.listen @port, =>
      @log "listening..."

    @upnode.on 'error', (err) =>
      @err err

    # this should be the upnode function above
    # @upnode.on 'connection', =>

    #let variables land
    process.nextTick =>
      @store.opts.peers?.forEach @add

  destroy: ->
    @log "destroy"
    @upnode.close()
    for dest, client of @clients
      client.destroy()

  add: (dest) ->

    return false if dest is @id
    return @clients[dest] if @clients[dest]

    {host, port} = helper.parseDestination dest

    unless host and port
      @log "Invalid destination '#{dest}'"
      return false

    client = new CommsClient(@, host, port)
    @clients[dest] = client
    @emit 'addClient', client
    client.once 'destroy', =>
      @remove client.id

    return client

  remove: (dest) ->
    return unless @clients[dest]
    @emit 'removeClient', @clients[dest]
    delete @clients[dest]
    @log "removed: '#{dest}'"

  #broadcast - will call API methods on all relavant clients
  broadcast: (fnName, args, filter = -> true) ->
    callback = helper.getCallback args
    fns = []
    err = null
    _.each @clients, (client, dest) ->
      unless client.connected and client.ready and filter client, dest
        return 
      fn = client.remote[fnName]
      unless fn
        err = "server method '#{fnName}' does not exist" 
        return false
      fns.push (cb) -> fn.apply(client.remote, args.concat(cb))

    if err
      callback err
    else
      # @log "broadcasting to '#{fnName}', to #{fns.length} clients"
      async.parallel fns, callback

  #expose methods to client
  makeApi: ->
    api =
      source: @id
      clients: _.keys @clients
      buckets: {}
      time: (cb) =>
        cb Date.now()
      pingBucket: (source, name, cb) =>
        res = @store.buckets.get(name)?.ping?(source) or { missing: true }
        res.source = @id
        cb null, res

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



