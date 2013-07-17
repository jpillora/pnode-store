
{EventEmitter} = require "events"

_ = require("lodash")
async = require "async"
Base = require "./base"
helper = require "./helper"
ObjectBackend = require "./backends/obj-backend"

#expected interface
bankendProps = 
  'async':'boolean'
  'get':'function'
  'getAll':'function'
  'set':'function'
  'del':'function'

class Bucket extends EventEmitter
  #default backend
  name: "Bucket"

  #public methods used for extending
  publics: ['getAll', 'get', 'set', 'del']

  constructor: (@store, @id, opts = {}) ->
    @log "created"
    _.bindAll @
    if opts.backend

      unless typeof opts.backend.create is 'function'
        @err "must export a 'create' function"

      create = opts.backend.create
      delete opts.backend
    else
      create = ObjectBackend.create

    @backend = create(opts)

    for prop, type of bankendProps
      if typeof @backend[prop] isnt type
        @err "backend must implement '#{prop}' #{type}"

    #a map of all clients with this bucket
    @clients = {}
    @history = []
    @t0 = null
    @tN = null

    # ping all existing *ready* clients
    if @store.server.status is "up"
      @pingAll()

    # new clients will ping us as they become ready
    
  pingAll: ->
    #ping all 
    @store.server.broadcast 'pingBucket', [@id, @store.server.id, @times(), @pingsRecieved]

  pingsRecieved: (err, pingList) ->
    @err err if err
    return if pingList.length is 0
    @log "pingList", pingList

  #fired when this bucket has been pinged
  # ping will: accept other bucket times
  #        and return this buckets times
  ping: (source, times) ->
    if source is @store.server.id
      @err "pinged by self..."

    @log "pinged by #{source} with times:", times

    #client 'source' just pinged, client must also have this bucket
    @clients[source] = true

    #if client exists and has data we need - retrive it
    client = @store.server.clients[source]
    if client and times.t0 and times.tN
      @retrieveHistory client, times

    return @times()

  retrieveHistory: (client, times) ->
    @log "get history..."

    delay = 10000
    t1 = times.t0
    t2 = times.tN + delay

    sendQuery = =>
      # setTimeout =>
      client.remote.queryBucket @id, t1, t2, @gotHistory
      # , delay

    if client.connected is true
      sendQuery()
    else
      client.once 'connected', sendQuery

  queryRange: (t1, t2, cb) ->

    @log "history query:",t1,t2,@times()

    keys = {}
    for h, i in @history
      unless t1 <= h.t <= t2
        @log "history skip", h
        continue 
      # @log "history query item", h
      if h.op is 'set'
        keys[h.key] = i
      else if h.op is 'del'
        keys[h.key] = null

    results = { items: {}, length: 0 }
    for k,i of keys
      continue if i is null
      h = @history[i]
      results.t0 = h.t unless results.t0
      results.tN = h.t
      results.items[h.key] = [h.t, h.value]
      results.length++

    cb null, results

  gotHistory: (err, results) =>
    return @log "history error: #{err}" if err
    return unless results.length > 0

    @log "got history: #{results.length}"

    #compare incoming results the corresponding time period
    for h, i in @history
      rk = h.key
      break if h.t < results.tN
      item = results.items[rk]
      #incoming doesnt have this item
      unless item
        continue

      #history contains a more recent version (includes deletes)
      if h.t > item[0]
        #wipe and skip
        results.items[rk] = null
        continue

    tmp = @history.length
    #remaining items need to be stored and spliced into history
    for k, arr of results.items
      continue if arr is null
      [t, v] = arr
      @backendOp 'set', [k, v], {history: false}
      @history.push {op:'set', key:k, value:v, t}

    #splice requires binary search - we'll quick sort instead for now
    @history.sort (a,b) -> if a.t > b.t then 1 else -1

    @log "history updated: #{tmp} -> #{@history.length}"

  #client lost - remove their flag
  pong: (source) ->
    @log "remove #{source}"
    @clients[source] = false

  # read methods - no propogation
  getAll: -> @backendOp 'getAll', arguments
  get: ->    @backendOp 'get', arguments

  # write methods - need to propogate changes 
  set: -> @asyncOp 'set', arguments
  del: -> @asyncOp 'del', arguments

  asyncOp: (op, args) ->
    args = helper.arr args
    callback = helper.getCallback args

    broadcastArgs = [@id].concat(args)
    async.parallel [
      #broadcast op to all other buckets 
      (cb) => @broadcastOp op, broadcastArgs.concat(cb)
      #do local op
      (cb) => @backendOp op, args.concat(cb)
    ], callback

  #broadcast operation, filtering clients missing this bucket
  broadcastOp: (op, args) =>
    # @log "broadcast #{op}: #{args[0]}"
    @store.server.broadcast op, args, @filterClients

  #interface to the given backend - enforces asynchrony
  backendOp: (op, args, opts = {}) ->
    args = helper.arr args
    callback = helper.getCallback args

    if @backend.async
      @backend[op].apply @backend, args.concat(callback)
    else
      process.nextTick =>
        err = null
        try
          res = @backend[op].apply @backend, args
        catch e
          err = e
        callback err, res

    if op in ['set','del']
      key = args[0]
      if typeof args[1] isnt 'function'
        value = args[1]
      # @log op, key, value or ''
      @emit op, key, value

      # @log "#{op}(#{args[0]}...)" + (if opts.remote then "from remote #{opts.remote}" else "")

      if opts.history isnt false
        item = { op, key, value, t: Date.now() }
        @t0 = item.t if @history.length is 0
        @tN = item.t
        @history.push item

    null

  backendSet: -> @backendOp 'set', arguments
  backendDel: -> @backendOp 'del', arguments

  times: -> { t0: @t0, tN: @tN }

  filterClients: (client, dest) ->
    !!@clients[dest]

#also extend base
Base.mixin Bucket

module.exports = Bucket