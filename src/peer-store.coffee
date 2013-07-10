_ = require("lodash")
fs = require("fs")
path = require("path")
mkdirp = require("mkdirp")
CommsServer = require("./comms-server")
helper = require("./helper")
Base = require("./base")
Bucket = require("./Bucket")
Set = require("./set")

defaults =
  debug: true
  port: 7557

#Constructor
PeerStore = class PeerStore extends Base
  name: "PeerStore"
  constructor: (options) ->

    unless _.isPlainObject options
      @err "Must specify options object"

    @opts = _.defaults options, defaults

    #for debugging
    @store = { opts: @opts }

    _.bindAll @
    @buckets = new Set()

    @defaultBucket = @bucket "default-peer-store"
    _.extend @, _.pick @defaultBucket, 'getAll', 'get', 'set', 'del'

    @server = new CommsServer @

  #get and insert a bucket with opts
  bucket: (name, opts) ->
    bucket = @buckets.get name
    return bucket if bucket
    #create a new bucket
    bucket = new Bucket @, name, opts
    @buckets.set name, bucket
    return bucket

  sessionStore: ->
    null

#exports
PeerStore.helper = helper
module.exports = PeerStore

