
# Use with express like so:
#
# app.use(express.session({
#   store: new P2PSessionStore(),
#   secret: 'secret'
# }));



connect = require("connect")
_ = require("underscore")
Base = require("./base")
fs = require("fs")
path = require("path")
mkdirp = require("mkdirp")

#Constructor
class SessionStore extends connect.session.Store

  name: "SessionStore"
  constructor: (@store) ->

  get: (sid, fn) ->
    @log "get: #{sid}"

  set: (sid, sess, fn) ->

  destroy: (sid, fn) ->

#also extend base
SessionStore::log = Base::log
SessionStore::err = Base::err
SessionStore::toString = Base::toString

module.exports = SessionStore