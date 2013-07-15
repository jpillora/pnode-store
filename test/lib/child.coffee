#directable store process
PeerStore = require "../../"
async = require "async"
name = null
store = null
buckets = {}

#helpers
guid = -> (Math.random() * Math.pow(2, 32)).toString(16)
rand = (max) -> (Math.floor(Math.random()*max))

ts =
  ms: 1
  s: 1000

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
    throw "store not started" unless store
    buckets[n] = store.bucket n

  insert: (n, times) ->
    for i in [1..times] by 1
      buckets[n].set "#{name}-#{n}-#{i}", rand(50)

  report: () ->
    throw "store not started" unless store
    data = {}

    getAll = (n, callback) ->
      store.bucket(n).getAll (err, results) ->
        throw err if err
        # console.log "BUCKET", n, err, results
        data[n] = results
        callback null

    async.map store.buckets.keys(), getAll, (err) ->
      throw err if err
      # console.log "REPORT", data
      process.send data

callAction = (action, args, delay) ->

  fn = fns[action]
  unless fn
    return process.send {error: "missing action: '#{action}'"}

  unless fn.length is args.length
    return process.send {error: "action: '#{action}' expects #{fn.length} args"}

  # console.log "+#{delay}ms"
  setTimeout ->
    try
      console.log "+#{delay}ms - CALLING #{action}(#{args.join(',')})"
      fn.apply null, args
    catch e
      process.send {error: e.toString()}
  , delay

  null

parseActions = (actions, delay = 0) ->
  for act,obj of actions
    if /^wait(\d+)(\w+)$/.test act
      t = ts[RegExp.$2]
      throw "Invalid time segment '#{RegExp.$2}'" unless t
      parseActions obj, delay + parseInt(RegExp.$1)*t
    else
      callAction act, obj, delay

#call a function
process.on 'message', (obj) ->
  name = obj.name
  parseActions obj.actions 

#caught error
process.on 'uncaughtException', (e) ->
  process.send {error: e.toString()}
