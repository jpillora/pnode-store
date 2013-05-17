
# Use with express like so:
#
# app.use(express.session({
#   store: new P2PSessionStore(),
#   secret: 'secret'
# }));

connect = require("connect")
udp = require("./udp")
_ = require("lodash")
difflet = require("difflet")
Peers = require("./peers")

#helpers
isArray = (val) ->
  Object::toString.call(val) is "[object Array]"
guid = ->
  (Math.random() * Math.pow(2, 32)).toString 16


objs = {}
#Constructor
module.exports = class P2PStore extends connect.session.Store

  name: "P2PStore"
  constructor: (options) ->
    @err "Must specify options"  unless options

    #super
    super options

    @err "Must specify a port"  unless options.port
    @port = options.port
    @peers = new Peers @, options.peers
    @sessions = {}
    @lasts = {}

  propogate: (data) ->
    @peers.pass data


  setSession: (sid, sess) ->
    @log "set: #{sid}"
    # if @sessions[sid]
    #   _.merge @sessions[sid], sess
    # else
    @sessions[sid] = sess
    null

  get: (sid, fn) ->
    @log "get: #{sid}"
    fn null, @sessions[sid]

  set: (sid, sess, fn) ->
    return unless fn

    @setSession sid, sess
    @propogate { action: "set", sid, sess }
    fn null

  destroy: (sid, fn) ->
    @log "delete: #{sid}"
    delete @sessions[sid]

    return  unless fn
    @propogate { action: "delete", sid }

    fn null

  toString: -> "#{@name}: #{@port}: "
  err: (str) -> throw new Error "#{@}#{str}"
  log: -> console.log.apply console, [@.toString()].concat _.toArray arguments
