#directable store process

PeerStore = require "/Users/jpillora/Code/Node/node-peer-store"
store = null
buckets = {}

fns =
  start: (port, peers) ->

    if typeof port isnt 'number'
      throw "port #{port} must be a number"

    peers = peers.map (p) ->
      if typeof p is 'number'
        return PeerStore.helper.getIp() + ':' + p
      return p

    store = new PeerStore
      debug: false
      port: port
      peers: peers
  bucket: (name) ->
    buckets[name] = store.bucket name
  add: (name, times = 1) ->
    i = 0
    while i < times
      buckets[name].set 'foo', 42
      i++

  report: () ->

    data = {}

    store.buckets.each (name, bucket) ->
      data[name] = 42

    process.send data


process.on 'message', (action) ->



  console.log "MESSAGE"
  {name, args} = action
  fn = fns[name]
  unless fn
    return process.send {error: "missing action: '#{name}'"}
  try
    fn.apply null, args
  catch e
    process.send {error: e.toString()}
  null

process.on 'uncaughtException', (e) ->
    process.send {error: e.toString()}