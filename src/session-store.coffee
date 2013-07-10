
# Use with express like so:
#
# app.use(express.session({
#   store: new P2PSessionStore(),
#   secret: 'secret'
# }));

connect = require("connect")
_ = require("lodash")
Base = require("./base")

#Constructor
class SessionStore extends connect.session.Store

  name: "SessionStore"
  constructor: (@store) ->

  get: (sid, fn) ->
    @log "get: #{sid}"

  set: (sid, sess, fn) ->

  destroy: (sid, fn) ->

#also extend base
Base.mixin SessionStore

module.exports = SessionStore