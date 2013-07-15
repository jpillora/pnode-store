
{EventEmitter} = require "events"

_ = require("lodash")
async = require "async"
Base = require "./base"
helper = require "./helper"
LRUBackend = require "./backends/lru-backend"

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

    if typeof @backend.async isnt 'boolean'
      @err "backend must set async to 'true' or 'false'"

    #a map of all clients with this bucket
    @clients = {}
    @history = []
    @t0 = null
    @tN = null

    @pingAll()

  pingAll: ->
    #ping all 
    @store.server.broadcast 'pingBucket', [@store.server.id, @id, @restoreHistory]

  restoreHistory: (err, pingList) ->
    @err err if err
    return if pingList.length is 0

    @log "pingList", pingList

    #TODO using retrieved histories AND client time diffs
    #     restore history by performing missing ops


  #fired when this bucket has been pinged
  ping: (source) ->
    if source is @store.server.id
      @err "pinged by self..."

    @log "pinged by #{source}"
    #client 'source' just pinged me, must also have this bucket
    @clients[source] = true
    return @times()

  #client lost - remove their flag
  pong: (source) ->
    @log "PONG #{source}"
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
        console.log 'sync op', op, res
        callback err, res

    @event op, args if op in ['set','del']
    null

  backendSet: -> @backendOp 'set', arguments
  backendDel: -> @backendOp 'del', arguments

  event: (op, args) ->
    key = args.shift()
    if typeof args[0] isnt 'function'
      value = args.shift()
    @log op, key, value or ''
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