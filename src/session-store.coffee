
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
guid = -> (Math.random() * Math.pow(2, 32)).toString 16


#Constructor
module.exports = class P2PStore extends connect.session.Store

  name: "P2PStore"
  constructor: (options) ->
    @err "Must specify options"  unless options
    #super
    super options
    @err "Must specify a port"  unless options.port

    _.bindAll @

    @port = options.port
    @peers = new Peers @, options.peers
    @sessions = {}
    @lasts = {}


  get: (sid, fn) ->
    @log "get: #{sid}"
    fn null, @sessions[sid]

  set: (sid, sess, fn) ->
    @_set sid, sess
    return unless fn
    @peers.send "set", sid, sess
    fn null

  _set: (sid, sess) ->
    @log "set: #{sid}"
    @sessions[sid] = sess
    null

  destroy: (sid, fn) ->
    @_destroy sid
    return unless fn
    @peers.send "destroy", sid
    fn null

  _destroy: (sid) ->
    @log "delete: #{sid}"
    delete @sessions[sid]
    null

  toString: -> "#{@name}: #{@port}: "
  err: (str) -> throw new Error "#{@}#{str}"
  log: -> console.log.apply console, [@.toString()].concat _.toArray arguments
