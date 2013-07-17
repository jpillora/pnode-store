#directable store process
PeerStore = require "../../"
async = require "async"
name = null
store = null
buckets = {}
inserts = 0

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
    throw "store not started" unless store
    buckets[n] = store.bucket n

  insert: insertTimes

  insertOver: (n, i, sec) ->
    throw "Invalid number" unless i > 0 and sec > 0

    ms = sec*1000
    
    itemN = 1
    itemI = i/ms

    while itemI < 30
      itemI *= 2
      itemN *= 2

    insert = ->
      insertTimes(n, itemN)
      i -= itemN
      if i > 0
        setTimeout insert, itemI
    insert()

  report: () ->
    throw "store not started" unless store
    data = {}

    getAll = (n, callback) ->
      store.bucket(n).getAll (err, results) ->
        data[n] = results
        callback err

    async.map store.buckets.keys(), getAll, (err) ->
      processSend err, data



insertRandom = (n) ->
  throw "bucket #{n} does not exist" unless buckets[n] 
  buckets[n].set "#{name}-#{n}-#{++inserts}", rand(100)
insertTimes = (n, i) ->
  throw "Invalid number" unless i > 0
  console.log "inserting #{i} into #{n}"
  insertRandom(n) while i-- > 0

callAction = (action, args, ms) ->

  fn = fns[action]
  unless fn
    throw "missing action: '#{action}'"

  unless fn.length is args.length
    throw "action: '#{action}' expects #{fn.length} args"

  # console.log "+#{ms}ms", action
  setTimeout ->
    try
      console.log "+++ #{ms}ms - CALLING #{action}(#{args.join(',')})"
      fn.apply null, args
    catch e
      processSend e.stack
  , ms

  null

parseActions = (actions) ->
  # console.log "+++", actions
  delay = 0
  for action in actions
    fnName = action.shift()
    args = action
    if fnName is 'wait'
      delay += args[0]
    else
      callAction fnName, args, delay*1000

processSend = (err, data) ->
  process.send {err, data}

#call a function
process.on 'message', (obj) ->
  name = obj.name
  parseActions obj.actions 

#caught error
process.on 'uncaughtException', (e) ->
  processSend e.stack
