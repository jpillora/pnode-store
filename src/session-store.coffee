
# Use with express like so:
#
# app.use(express.session({
#   store: store.sessionStore(),
#   secret: 'secret'
# }));

connect = require("connect")
_ = require("lodash")
Base = require("./base")

#Constructor
class SessionStore extends connect.session.Store

  name: "SessionStore"
  constructor: (@store) ->
    @bucket = @store.bucket 'default-session-store'

  get: (sid, fn) ->
    @bucket.get sid, (err, res) -> fn(err, res)   

  set: (sid, session, fn) ->
    @bucket.set sid, session, (err, res) -> fn(err)   

  destroy: (sid, fn) ->
    @bucket.del sid, (err, res) -> fn(err) if fn

#also extend base
Base.mixin SessionStore

module.exports = SessionStore