
{EventEmitter} = require "events"

module.exports = class Set extends EventEmitter

  constructor: ->
    @_obj = {}

  get: (k) ->
    @emit 'get', k
    return @_obj[k]

  set: (k,v) ->
    @_obj[k] = v
    @emit 'set', k, v
    true

  del: (k) ->
    @emit 'get', k
    delete @_obj[k]
    true

  has: (k) ->
    !!@_obj[k]

  keys: ->
    Object.keys @_obj
