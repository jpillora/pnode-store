
# Use with express like so:
#
# app.use(express.session({
#   store: new P2PSessionStore(),
#   secret: 'secret'
# }));



connect = require("connect")
_ = require("underscore")
fs = require("fs")
path = require("path")
mkdirp = require("mkdirp")
# difflet = require("difflet")
Peers = require("./peers")

#helpers
guid = ->
  (Math.random() * Math.pow(2, 32)).toString 16

# mem = ->
#   console.log _.map(process.memoryUsage(), (val, name) ->
#     name + ': ' + (Math.round(val / 1024 / 1024* 100) / 100) + ' MB'
#   , null, 2).join(', ')

# setInterval mem, 5000

os = require "os"
getLocalIp = (regex) ->
  for name, addrs of os.networkInterfaces()
    for addr in addrs
      if addr.family is 'IPv4' and (not regex or regex.test addr.address)
        return addr.address
  return null

#Constructor
module.exports = class P2PStore extends connect.session.Store

  name: "P2PStore"
  constructor: (options) ->
    @err "Must specify options"  unless options
    #super
    super options
    @err "Must specify a port"  unless options.port

    _.bindAll @
    @_persist = _.debounce @_persist, options.persistDelay or 5000

    @host = getLocalIp(options.subnet or /^172\./) or "127.0.0.1"
    @port = options.port
    @peers = new Peers @, options.peers
    @debug = options.debug or false
    @tmpDir = path.join process.cwd(), 'tmp'
    @dataFile = path.join @tmpDir, 'data.json'
    @data = @_restore() or {
      user: {}
      sessions: {}
    }
    @lasts = {}

  get: (sid, fn) ->
    @log "get: #{sid}"
    fn null, @data.sessions[sid]

  set: (sid, sess, fn) ->
    @_set sid, sess
    @peers.send { method: "set", sid, sess }
    fn null if fn

  _set: (sid, sess) ->
    @log "set: #{sid}"
    @data.sessions[sid] = sess
    @_persist()
    null

  destroy: (sid, fn) ->
    @_destroy sid
    @peers.send { method: "destroy", sid }
    fn null if fn

  _destroy: (sid) ->
    @log "delete: #{sid}"
    delete @data.sessions[sid]
    @_persist()
    null

  setData: (key, obj) ->
    @data.user[key] = obj
    @_persist()

  getData: (key) ->
    @data.user[key]

  _persist: ->
    json = JSON.stringify @data
    return if json is @_persisted
    fs.writeFile @dataFile, json, (err) =>
      if err
        @log "error persisting data store: #{err}"
      else
        @log "data store persisted"
        @_persisted = json

  _restore: ->
    mkdirp.sync @tmpDir
    return null unless fs.existsSync @dataFile
    json = fs.readFileSync @dataFile
    return unless json
    try
      data = JSON.parse json
      @log "data store restored"
      @_persisted = json
      return data
    catch e

    return null

  toString: -> "#{@host}:#{@port}: "
  err: (str) -> throw new Error "#{@}#{str}"
  log: ->
    return unless @debug
    console.log.apply console, [@.toString()].concat _.toArray arguments
