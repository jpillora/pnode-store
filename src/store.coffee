
{EventEmitter} = require 'events'

stores = {}

exports.name = 'store'
exports.fn = (opts) ->
  if stores[@id]
    return stores[@id]
  return stores[@id] = new Store @, opts

class Store extends EventEmitter
  constructor: (@peer, opts) ->
    if typeof opts is 'string'
      opts = name: opts

    @opts = opts
    @channel = "_store-#{opts.name}"

    @fresh = true
    @obj = {}

    #dynamic expose the initial state
    exposed = {}
    exposed[opts.name] = @peer.exposeDynamic => @obj
    @peer.expose _store: exposed

    #only preload each remote once
    preloads = []
    
    preload = (remote) =>
      obj = remote._store?[opts.name]
      return unless typeof obj is 'object'
      return if preloads.indexOf(obj) >= 0
      #silently merge existing data
      for k,v of obj
        @set k, v, true, true
      preloads.push obj
      return

    #grab existing remotes
    if @peer.name is 'Client'
      @peer.server preload
    else if @peer.name is 'Server' or @peer.name is 'LocalPeer'
      @peer.all (remotes) -> remotes.forEach preload

    #grab new prefilled remotes
    @peer.on 'remote', preload

    #subscribe to subsequent changes
    @peer.subscribe @channel, (doDelete, pathStr, value, merge) =>
      @set pathStr, (if doDelete then undefined else value), merge, true

  object: ->
    @obj

  set: (pathStr, value, merge, silent) ->
    
    #dont bother merging into an empty object
    if @fresh
      merge = false
      @fresh = false

    #merge instead of replace
    if merge and typeof value is 'object'
      for k,v of value
        if /^\d+$/.test k
          k = "[#{k}]"
        else if /^\d/.test(k) or /[^\w]/.test k
          k = "['#{k}']"
        else if pathStr
          k = "." + k
        @set pathStr+k, v, true, silent
      return

    #replace 
    doDelete = value is undefined

    path = parsePath pathStr
    #at least 1 path entry required
    return if path.length is 0

    prop = path.pop()

    #derefernce path, while creating missing props
    o = deref @obj, path, not doDelete
    return unless o

    if doDelete
      delete o[prop]
    else
      o[prop] = value

    @peer.publish @channel, doDelete, pathStr, value, merge unless silent
    @emit 'change', pathStr, value

  del: (pathStr) ->
    return @set pathStr

  get: (pathStr) ->
    return deref @obj, parsePath pathStr

# ===============
# helpers
# ===============

deref = (o, pathArr, create) ->
  while pathArr.length
    prop = pathArr.shift()
    unless o[prop]
      return unless create
      o[prop] = {}
    o = o[prop]
  return o

parse = (str) ->
  eq = str.indexOf("=")
  return  if eq is -1 #invalid
  json = str.substr(eq + 1)
  pathStr = str.substr(0, eq)
  val
  if json
    try val = JSON.parse(json)
    catch e
      e.message = "JSON Error: " + e.message
      throw e

  path: parsePath pathStr
  val: val

parsePath = (str) ->
  return [] if str is ''
  str = '.' + str if str.charAt(0) isnt '.'
  path = []
  while /^(\[(\d+)\]|\[\'([^']+)\'\]|\.([a-zA-Z]\w+))/.test(str)
    p = RegExp.$2 or RegExp.$3 or RegExp.$4
    str = str.replace(RegExp.$1, "")
    path.push p
  return path

#place on window
if process.browser
  window.pnodeStore = module.exports
