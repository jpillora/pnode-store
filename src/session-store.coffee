
# Use with express like so:
#
# app.use(express.session({
#   store: new P2PSessionStore(),
#   secret: 'secret'
# }));



connect = require("connect")
_ = require("lodash")
difflet = require("difflet")
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

    @host = getLocalIp(options.subnet or /^172\./) or "127.0.0.1"
    @port = options.port
    @peers = new Peers @, options.peers
    @sessions = {}
    @lasts = {}

  get: (sid, fn) ->
    @log "get: #{sid}"
    fn null, @sessions[sid]

  set: (sid, sess, fn) ->
    @_set sid, sess
    @peers.send { method: "set", sid, sess }
    fn null if fn

  _set: (sid, sess) ->
    @log "set: #{sid}"
    @sessions[sid] = sess
    null

  destroy: (sid, fn) ->
    @_destroy sid
    @peers.send { method: "destroy", sid }
    fn null if fn

  _destroy: (sid) ->
    @log "delete: #{sid}"
    delete @sessions[sid]
    null

  toString: -> "#{@host}:#{@port}: "
  err: (str) -> throw new Error "#{@}#{str}"
  log: -> console.log.apply console, [@.toString()].concat _.toArray arguments
