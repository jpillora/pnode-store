
_ = require("lodash")
Base = require("./base")
helper = require("./helper")
CommsClient = require("./client")
Bucket = require("./Bucket")
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
    @status = "down"

    #clients
    @clients = {}

    #give connection the api
    @upnodeDaemon = upnode (remote, dnode) =>

      client = null

      dnode.on 'error', (e) =>
        @err "dnode error: #{e.stack}"
        if client
          client.destroy()


      @log "UPNODE CONNECTION"
      #when a client connects to us
      dnode.on 'remote', =>

        @log "UPNODE REMOTE"

        #add remote and all of it's peers
        client = @addClient remote.source
        unless client
          @err "recieved connection from self..."

        #store connection info
        client.internal = {remote,dnode}

        #add peers
        remote.peers.forEach @addClient


      #dynamic api methods
      return @makeApi()

    @upnode = @upnodeDaemon.listen @port, =>
      @log "listening..."
      @status = "up"
      @emit "up"

    # this should be the upnode function above
    # @upnode.on 'connection', =>

    #allow variables land before
    setTimeout =>
      @store.opts.peers?.forEach @addClient
    , 50

  destroy: ->
    @log "destroy"
    @status = "down"
    @emit "down"
    @upnode.close()
    for dest, client of @clients
      client.destroy()

  addClient: (dest) ->

    return false if dest is @id
    return @clients[dest] if @clients[dest]

    {host, port} = helper.parseDestination dest

    unless host and port
      @log "Invalid destination '#{dest}'"
      return false

    client = new CommsClient(@, host, port)
    @clients[dest] = client
    
    @emit 'addClient', client

    client.on 'ready', =>
      @emit 'readyClient', client

    client.once 'destroy', =>
      @removeClient client.id

    return client

  removeClient: (dest) ->
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
      pingBucket: (name, source, times, cb) =>
        res = @store.buckets.get(name)?.ping?(source, times) or {}
        res.source = @id
        cb null, res

    # add public bucket methods
    # calls are all to sent to their backend (do not trigger further broadcasts)
    Bucket::publics.forEach (fnName) =>
      api[fnName] = =>
        args = helper.arr arguments
        callback = args[args.length-1]
        if typeof callback isnt 'function'
          @err "bucket: #{bucketName}: '#{fnName}': callback missing"

        bucketName = args.shift()
        bucket = @store.buckets.get bucketName
        unless bucket
          return callback "has no bucket: #{bucketName}"

        @log "#{bucketName}.#{fnName}('#{args[0]}'...)"
        bucket.backendOp fnName, args

    return api



