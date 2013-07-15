
require "colors"
coffee = require "coffee-script"
{fork} = require "child_process"
util = require "util"
fs = require "fs"
path = require "path"
colors = ["blue", "green", "cyan", "yellow"]

#compile into temp for forking
storeFile = path.join process.env.TMPDIR, 'store.js'
storeCoffee = fs.readFileSync(path.join __dirname, 'store.coffee').toString()
fs.writeFileSync storeFile, coffee.compile storeCoffee

runServer = (i, name, actions, cb) ->
  
  color = colors[i]
  log = (str, c) ->
    console.log name, str.toString().replace(/\n$/, "")[c]

  log "Starting '#{name}'", color

  proc = fork(storeFile, [], {silent:true})

  proc.stdout.on "data", (buffer) ->
    log buffer, color

  proc.stderr.on "data", (buffer) ->
    log buffer, 'red'
    cb buffer.toString()
    proc.kill()

  #process returned a result
  proc.on 'message', (result) ->
    str = JSON.stringify(result)
    log "#{name}: #{str}", if result.error then 'red' else 'white'
    cb result.error or null, result

  #send process all actions to execute
  proc.send {name, actions}

  return proc

exports.run = (test, callback) ->

  procs = []
  results = []
  cb = (err, data) ->
    #accumulate data
    results.push data
    return unless err or results.length is procs.length
    #kill all
    proc.kill() for proc in procs
    #return results to test
    callback err, results

  #start test
  for serverName, actions of test
    proc = runServer procs.length, serverName, actions, cb
    procs.push proc

  null