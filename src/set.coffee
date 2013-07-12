
Base = require "./base"

module.exports = class Set extends Base

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

  each: (fn) ->
    for k,v of @_obj
      fn k,v
    null

  map: (fn) ->
    res = []
    for k,v of @_obj
      res.push fn k,v
    res