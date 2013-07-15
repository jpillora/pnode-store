
# lru-cache implementation of a peer-store bucket
# - 'create' must return an object with:
#     async: true/false
#     get: fn
#     set: fn
#     del: fn
# - 'async' will dictate whether peer store will either call:
#     fn(args..., callback) or
#     fn(args...)
#  * callback must follow node-style (err, result)

LRU = require 'lru-cache'

class LRUBackend

  async: false

  constructor: (options) ->
    @cache = LRU options
  
  get: (key) ->
    res = @cache.get(key)
    console.log 'LRUBackend', 'get', key, res
    return res
  
  set: (key, val) ->
    res = @cache.set(key, val)
    console.log 'LRUBackend', 'set', key, val, res
    return res
  
  del: (key) ->
    return @cache.del(key)
  
  getAll: ->
    obj = {}
    @cache.forEach (val,key) ->
      obj[key] = val
    return obj
  
  getByKeys: (keys) ->
    obj = {}
    keys.forEach (key) =>
      obj[key] = @cache.get(key)
    return obj

exports.create = (options) ->
  return new LRUBackend options