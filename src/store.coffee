
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
    @opts.read ?= true
    @opts.write ?= true
    @opts.debug ?= false

    if @opts.debug
      @on 'change', (path, val) ->
        console.log "pnode-store: change: '%s':", path, val

    @channel = "_store-#{opts.name}"
    @obj = {}

    #dynamic expose the initial state
    if @opts.write
      exposed = {}
      exposed[opts.name] = @peer.exposeDynamic =>
        # console.log "sending curr", JSON.stringify @obj,null,2
        @obj
      @peer.expose _store: exposed

    #update store from peers
    if @opts.read
      #only preload each remote once
      preloads = []
      preload = (remote) =>
        obj = remote._store?[opts.name]
        return unless typeof obj is 'object'
        return if preloads.indexOf(obj) >= 0
        #silently merge existing data
        @set [], obj, true
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
      @peer.subscribe @channel, (path, doDelete, value) =>
        @set path, (if doDelete then undefined else value), true

    return

  object: ->
    @obj

  set: (path, value, silent) ->

    unless path instanceof Array
      throw new Error("set(path) must be an array")

    if path.length is 0
      if typeof value is 'object'
        for k,v of value
          @set [k], v
        return
      else
        throw new Error("set(path, #{value}) array must be at least one property long");

    @setAcc @obj, [], path, value, silent

  setAcc: (obj, used, path, value, silent) ->

    prop = path.shift()
    unless prop
      throw new Error "property missing ([#{used.join(',')}])"
    used.push prop

    if path.length > 0 and typeof obj[prop] is 'object'
      return @setAcc obj[prop], used, path, value, silent

    doDelete = value is undefined

    if doDelete
      delete obj[prop]
    else
      obj[prop] = value

    if not silent and @opts.write
      @peer.publish @channel, used, doDelete, value

    @emit 'change', used, value

  del: (path) ->
    return @set path

  get: (path) ->
    o = @obj
    while path.length
      o = o[path.shift()]
    return o

# ===============
# helpers
# ===============

dotOp = (path) ->

deref = (o, pathArr, create) ->
  while pathArr.length
    prop = pathArr.shift()
    unless o[prop]
      return unless create
      o[prop] = {}
    o = o[prop]
  return o

pathify = (prop) ->
  return if /^\d+$/.test prop
    "[#{prop}]"
  else if /^\d/.test(prop) or /[^\w]/.test(prop)
    "['#{prop}']"
  else
    prop

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
  str = '.' + str unless /^(\.|\[)/.test str
  path = []
  while /^(\[(\d+)\]|\[\'([^']+)\'\]|\.([a-zA-Z]\w+))/.test(str)
    p = RegExp.$2 or RegExp.$3 or RegExp.$4
    str = str.replace(RegExp.$1, "")
    path.push p
  return path

#place on window
if process.browser
  window.pnodeStore = module.exports
