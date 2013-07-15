
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
    @log '<GET', sid
    @bucket.get sid, (err, res) =>
      @log '>GET', sid, err or res
      fn(err, res)   

  set: (sid, session, fn) ->
    @log '<SET', sid
    @bucket.set sid, session, (err, res) =>
      @log '>SET', sid, err, res
      fn(err, session)   

  destroy: (sid, fn) ->
    @log '<DEL', sid
    @bucket.del sid, (err, res) =>
      @log '>DEL', sid, err or res
      fn(err, res) if fn   

#also extend base
Base.mixin SessionStore

module.exports = SessionStore