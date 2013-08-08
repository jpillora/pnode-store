_ = require "lodash" 
fs = require "fs" 
path = require "path" 
mkdirp = require "mkdirp" 
CommsServer = require "./server" 
helper = require "./helper" 
Base = require "./base" 
Bucket = require "./bucket" 
SessionStore = require "./session-store" 
Set = require "./set" 
backends = require "./backends"

defaults =
  debug: false
  port: 7557
  backend: 'obj'

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

    #notify all buckets of client readys
    @server.on 'remoteClient', (remote, dnode) =>
      @log "client remote"
      buckets = remote?.buckets
      unless buckets
        @log "no buckets"
        return

      dnode.once 'data', =>
        _.each buckets, (times, name) =>
          @buckets.get(name)?.ping(remote.source, times)

    #notify all buckets of client removals
    @server.on 'removeClient', (client) =>
      @buckets.each (name, bucket) =>
        bucket.pong client.id

    #create the default bucket
    @defaultBucket = @bucket "default-peer-store"
    #extend this interface by the default bucket
    Bucket::publics.forEach (fn) =>
      @[fn] = @defaultBucket[fn]

  #get and insert a bucket with opts
  bucket: (name, backendName, opts) ->

    bucket = @buckets.get name
    return bucket if bucket

    backendClass = null

    if typeof backendName is 'string'
      backendClass = backends.get backendName
      unless backendClass
        @err "backend '#{backendName}' is missing"
    else
      opts = backendName
      #no backend defined, use default
      backendClass = backends.get @opts.backend

    #create instance
    backend = backendClass.create opts

    #validate instance
    for prop, type of backends.props
      if typeof backend[prop] isnt type
        @err "backend must implement '#{prop}' #{type}"

    #create a new bucket
    bucket = new Bucket @, name, backend
    @buckets.set name, bucket
    return bucket

  sessionStore: (opts) ->
    unless @sessionStore.inst
      @sessionStore.inst = new SessionStore @
    @sessionStore.inst

  destroy: ->
    @log "END SERVER"
    @server.destroy()

#exports
PeerStore.helper = helper
PeerStore.addBackend = require("./backends").add
module.exports = PeerStore

