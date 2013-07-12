
require "colors"
coffee = require "coffee-script"
{fork} = require "child_process"
util = require "util"
fs = require "fs"
path = require "path"
colors = ["blue", "cyan", "yellow", "green"]

#compile into temp for forking
storeFile = path.join process.env.TMPDIR, 'store.js'
storeCoffee = fs.readFileSync(path.join __dirname, 'store.coffee').toString()
fs.writeFileSync storeFile, coffee.compile storeCoffee

runAction = (proc, action) ->

  console.log "running... '#{util.inspect action}'"
  name = action.shift()

  if name is 'in'
    t = action.shift()
    throw "must be number" unless typeof t is 'number'
    actions = action.shift()
    setTimeout ->
      runActions proc, actions
    , t
  else
    proc.send {name, args: action}

runActions = (proc, actions) ->
  actions.forEach (action) ->
    runAction proc, action

runServer = (i, name, actions, cb) ->
  
  color = colors[i]
  console.log "Starting '%s' as %s", name, color

  proc = fork(storeFile, silent:false)

  console.log "!"
  console.log proc.stdout

  console.log "RUN SERVER", proc.pid, proc.stdout, proc.stderr

  log = (str, c) ->
    console.log name, str.toString().replace(/\n$/, "")[c]

  # proc.stdout?.on "data", (buffer) ->
  #   log buffer, color
  # proc.stderr?.on "data", (buffer) ->
  #   log buffer, 'red'
  #   cb buffer.toString()

  proc.on 'message', (result) ->
    if result.error
      cb result.error
      log JSON.stringify(result), 'red'
      return
    log JSON.stringify(result), 'cyan'
    cb null, result

  runActions proc, actions

  return proc

exports.run = (timeout, test, callback) ->

  procs = []
  results = []
  cb = (err, data) ->
    if err
      for proc in procs
        console.log "KILL EVERYTHINGGG"
        proc.kill()
      callback(err)
      return
    results.push data
    if results.length is procs.length
      callback null, results
    null

  for serverName, actions of test
    proc = runServer procs.length, serverName, actions, cb
    procs.push proc

  setTimeout ->
    procs.forEach (p) -> p.send {name:'report'}
  , timeout-1000

  null