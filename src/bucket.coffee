
{EventEmitter} = require "events"

_ = require("lodash")
async = require "async"
Base = require "./base"
LRUBackend = require "./backends/lru-backend"

class Bucket extends EventEmitter
  #default backend
  name: "Bucket"
  constructor: (@store, @id, opts = {}) ->

    _.bindAll @

    @ops = 0

    if opts.backend?.create?
      create = opts.backend.create
      delete opts.backend
    else
      create = LRUBackend.create

    @backend = create(opts)

    if typeof @backend.async isnt 'boolean'
      @err "backend must set async to 'true' or 'false'"

    @_obj = {}

  #for testing
  getAll: (callback) ->
    @log "getAll"
    callback null, @backend.getAll()

  get: (key, callback) ->
    @log "get", key

    if @backend.async
      @backend.get key, callback
    else
      item = @backend.get key
      #force asynchrony
      process.nextTick ->
        callback null, item

  #get is 'backendGet'

  set: (key, value, callback) ->
    async.parallel [
      #broadcast to all 'backendSet'
      (cb) => @store.server.set @id, key, value, cb
      #do local 'backendSet'
      (cb) => @backendSet key, value, cb
    ], callback

  backendSet: (key, value, callback) ->
    @ops++
    @log @ops, "set", key, value
    @emit 'set', key, value

    if @backend.async
      @backend.set key, value, callback
    else
      res = @backend.set key, value
      #force asynchrony
      process.nextTick ->
        callback if res is false then "set fail - returned false" 

    null

  del: (key, callback) ->
    async.parallel [
      #broadcast to all 'backendDel'
      (cb) => @store.server.del @id, key, cb
      #do local 'backendDel'
      (cb) => @backendDel key, cb
    ], callback

  backendDel: (key, callback) ->

    @ops++
    @log "del", key
    @emit 'del', key

    if @backend.async
      @backend.del key, callback
    else
      res = @backend.del key
      #force asynchrony
      process.nextTick ->
        callback if res is false then "del fail - returned false" 
    null


#also extend base
Base.mixin Bucket

module.exports = Bucket