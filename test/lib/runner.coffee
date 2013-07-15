
require "colors"
{fork} = require "child_process"
util = require "util"
colors = ["blue", "green", "cyan", "yellow"]

#compile child for forking
coffee = require "coffee-script"
fs = require "fs"
path = require "path"
childFile = path.join __dirname, 'child.js'
childCoffee = fs.readFileSync(path.join __dirname, 'child.coffee').toString()
fs.writeFileSync childFile, coffee.compile childCoffee

runServer = (i, name, actions, cb) ->
  
  color = colors[i]
  log = (str, c) ->
    console.log name, str.toString().replace(/\n$/, "")[c]

  log "Starting '#{name}'", color

  proc = fork(childFile, [], {silent:true})

  proc.stdout.on "data", (buffer) ->
    log buffer, color

  proc.stderr.on "data", (buffer) ->
    log buffer, 'red'
    cb buffer.toString()
    proc.kill()

  #process returned a result
  proc.on 'message', (result) ->
    # str = JSON.stringify(result)
    # log "#{name}: #{str}", if result.error then 'red' else 'white'
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