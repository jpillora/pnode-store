_ = require("underscore")
fs = require("fs")
path = require("path")
mkdirp = require("mkdirp")
CommsServer = require("./comms-server")
helper = require("./helper")
LRUBucket = require("./buckets/lru-bucket")
Base = require("./base")

defaults =
  debug: true
  port: 7557
  bucketType: LRUBucket

#Constructor
module.exports = class PeerStore extends Base
  name: "PeerStore"
  constructor: (options) ->

    unless _.isPlainObject options
      @err "Must specify options object"

    @opts = _.defaults options, defaults

    #for debugging
    @store = { opts: @opts }

    _.bindAll @
    @buckets = {}
    @peers = new CommsServer @

  addBucket: (name, opts, callback) ->
    if @getBucket name
      @err "Bucket already exists: #{name}"
    
    @buckets[name] = @opts.bucketType.create opts

    #prefill bucket
    #...
    #callback...

    return null

  getBucket: (name) ->
    @buckets[name]
