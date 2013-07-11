
{EventEmitter} = require "events"

_ = require("lodash")
async = require "async"
Base = require "./base"
helper = require "./helper"
LRUBackend = require "./backends/lru-backend"

class Bucket extends EventEmitter
  #default backend
  name: "Bucket"
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

    @history = []
    @t0 = null
    @tN = null

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
      #broadcast to all 'backendDel'
      (cb) => @store.server.broadcast(op, broadcastArgs.concat(cb))
      #do local 'backendDel'
      (cb) => @backendOp op, args.concat(cb)
    ], callback

  backendOp: (op, args) ->
    args = helper.arr args
    callback = helper.getCallback args

    if @backend.async
      @backend[op].apply @backend, args.concat(callback)
    else
      res = @backend[op].apply @backend, args
      #force asynchrony
      process.nextTick ->
        callback if res is false then "#{op} failed (returned false)" 

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

  times: ->
    _.pick @, 't0', 'tN'

#also extend base
Base.mixin Bucket

module.exports = Bucket