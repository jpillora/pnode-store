_ = require("lodash")
fs = require("fs")
path = require("path")
mkdirp = require("mkdirp")
CommsServer = require("./server")
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

    @id = helper.guid()

    unless _.isPlainObject options
      @err "Must specify options object"

    _.bindAll @

    @opts = _.defaults options, defaults
    #for debugging
    @store = { opts: @opts }
    
    @server = new CommsServer @
    @buckets = new Set()

    #notify all buckets of client removals
    @server.on 'removeClient', (client) =>
      @buckets.each (name, bucket) =>
        bucket.pong client.id

    #create the default bucket
    @defaultBucket = @bucket "default-peer-store"
    #extend its interface
    Bucket::publics.forEach (fn) =>
      @[fn] = @defaultBucket[fn]

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

  destroy: ->
    @log "END SERVER"
    @server.destroy()

#exports
PeerStore.helper = helper
module.exports = PeerStore

