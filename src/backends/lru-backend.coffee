
# lru-cache implementation of a peer-store bucket
# - 'create' must return an object with:
#     async: true/false
#     get: fn
#     set: fn
#     del: fn
# - 'async' will dictate whether peer store will either call:
#     get(key, callback) or
#     get(key)
#  * callback must follow node-style (err, result)

LRU = require 'lru-cache'

exports.create = (options) ->
  cache = LRU options
  
  async: false
  get: cache.get.bind(cache)
  set: cache.set.bind(cache)
  del: cache.del.bind(cache)
  getAll: ->
    obj = {}
    cache.forEach (val,key) -> obj[key] = val
    return obj


