
{EventEmitter} = require "events"

_ = require("lodash")
async = require "async"
Base = require "./base"
helper = require "./helper"
LRUBackend = require "./backends/lru-backend"

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
    if opts.backend?.create?
      create = opts.backend.create
      delete opts.backend
    else
      create = LRUBackend.create

    @backend = create(opts)

    for prop, type of bankendProps
      if typeof @backend[prop] isnt type
        @err "backend must implement '#{prop}' of type '#{type}'"

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
    @store.server.broadcast 'pingBucket', [@id, @store.server.id, @times(), @restoreHistory]

  restoreHistory: (err, pingList) ->
    @err err if err
    return if pingList.length is 0

    @log "pingList", pingList

    #TODO using retrieved histories AND client time diffs
    #     restore history by performing missing ops

  #fired when this bucket has been pinged
  # ping will: accept other bucket times
  #        and return this buckets times
  ping: (source, times) ->
    if source is @store.server.id
      @err "pinged by self..."

    @log "pinged by #{source} with times:", times

    #client 'source' just pinged, client must also have this bucket
    @clients[source] = true

    client = @store.server.clients[source]
    if client
      client.log

    return @times()

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
  backendOp: (op, args) ->
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

    @event op, args if op in ['set','del']
    null

  backendSet: -> @backendOp 'set', arguments
  backendDel: -> @backendOp 'del', arguments

  event: (op, args) ->
    key = args[0]
    if typeof args[1] isnt 'function'
      value = args[1]
    # @log op, key, value or ''
    @emit op, key, value
    item = { op, key, value, t: Date.now() }

    @t0 = item.t if @history.length is 0
    @tN = item.t
    @history.push item

  times: -> { t0: @t0, tN: @tN }

  filterClients: (client, dest) ->
    !!@clients[dest]

#also extend base
Base.mixin Bucket

module.exports = Bucket