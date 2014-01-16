
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
    @obj = {}

    #dynamic expose the initial state
    exposed = {}
    exposed[opts.name] = @peer.exposeDynamic => @obj
    @peer.expose _store: exposed

    preload = (remote) =>
      obj = remote._store?[opts.name]
      return unless obj
      #silently merge existing data
      @set '', obj, true, true

    #grab existing remotes
    if @peer.name is 'Client'
      @peer.server preload
    else if @peer.name is 'Server' or @peer.name is 'LocalPeer'
      @peer.all (remotes) -> remotes.forEach preload

    #grab new prefilled remotes
    @peer.on 'remote', preload

    #subscribe to subsequent changes
    @peer.subscribe @channel, (action, pathStr, value, merge) =>
      @set pathStr, (if action is 'del' then undefined else value), merge, true

  object: ->
    @obj

  set: (pathStr, value, merge, silent) ->
    
    if merge and typeof value is 'object'
      for k,v of value
        @set "#{pathStr}#{if pathStr then '.' else ''}#{k}", v, true, silent
      return

    action = if value is undefined then 'del' else 'set'

    path = parsePath pathStr
    prop = path.pop()

    o = deref @obj, path, action is 'set'
    return unless o

    if action is 'del'
      delete o[prop]
    else
      o[prop] = value

    @peer.publish @channel, action, pathStr, value, merge unless silent
    @emit action, pathStr, value

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
  while /^(\.(\w+)|\[(\d+)\])/.test(str)
    p = RegExp.$2 or RegExp.$3
    str = str.replace(RegExp.$1, "")
    path.push p
  return path
