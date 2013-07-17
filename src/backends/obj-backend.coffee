
# plain object implementation of a peer-store bucket

# - 'create' must return an object with:
#     async: true/false
#     get: fn
#     set: fn
#     del: fn
# - 'async' will dictate whether peer store will either call:
#     fn(args..., callback) or
#     fn(args...)
#  * callback must follow node-style (err, result)

class ObjectBackend

  async: false

  constructor: (options) ->
    @data = {}
  
  get: (key) ->
    return @data[key]
  
  set: (key, val) ->
    return @data[key] = val
  
  del: (key) ->
    delete @data[key]
    return true
  
  getAll: ->
    #copy data
    obj = {}
    for k,v of @data
      obj[k] = v
    return obj

exports.create = (options) ->
  return new ObjectBackend options


  