#directable store process

PeerStore = require "/Users/jpillora/Code/Node/node-peer-store"
name = null
store = null
buckets = {}

#helpers
guid = -> (Math.random() * Math.pow(2, 32)).toString(16)
rand = (max) -> (Math.floor(Math.random()*max))

fns =
  start: (port, peers) ->
    if typeof port isnt 'number'
      throw "port #{port} must be a number"

    peers = peers.map (p) ->
      if typeof p is 'number'
        return PeerStore.helper.getIp() + ':' + p
      return p

    store = new PeerStore
      debug: true
      port: port
      peers: peers

  create: (n) ->
    buckets[n] = store.bucket n

  insert: (n, times) ->
    for i in [0..times] by 1
      buckets[n].set "#{name}-#{n}-#{guid()}", rand(50)

  report: () ->
    data = {}
    store.buckets.each (n, bucket) ->
      data[n] = 42
    console.log "REPORT", data
    process.send data

callAction = (action, args, delay) ->

  fn = fns[action]
  unless fn
    return process.send {error: "missing action: '#{action}'"}

  unless fn.length is args.length
    return process.send {error: "action: '#{action}' expects #{fn.length} args"}

  setTimeout ->
    try
      console.log "+#{delay}s - CALLING #{action}(#{args.join(',')})"
      fn.apply null, args
    catch e
      process.send {error: e.toString()}
  , delay*1000

  null

parseActions = (actions, delay = 0) ->
  for act,obj of actions
    if /^wait(\d+)$/.test act
      parseActions obj, delay + parseInt RegExp.$1
    else
      callAction act, obj, delay

#call a function
process.on 'message', (obj) ->
  name = obj.name
  parseActions obj.actions 

#caught error
process.on 'uncaughtException', (e) ->
  process.send {error: e.toString()}
