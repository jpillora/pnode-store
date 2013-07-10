
os = require "os"

defaultSubnets = [
  /^10\./
  /^172\./
  /^192\./
  /^[^0]\./
]

#choose first ip to match a subnet
exports.getIp = (subnets = defaultSubnets) ->
  for name, addrs of os.networkInterfaces()
    for regex in subnets
      for addr in addrs
        if addr.family is 'IPv4'
          if regex.test addr.address
            return addr.address
  return null

exports.guid = ->
  (Math.random() * Math.pow(2, 32)).toString 16

exports.parseDestination = (str) ->
  if /^(.+?)(:(\d+))?$/.test(str)
    return { host: RegExp.$1, port: parseInt RegExp.$3, 10 }
  return {}

# mem = ->
#   console.log _.map(process.memoryUsage(), (val, name) ->
#     name + ': ' + (Math.round(val / 1024 / 1024* 100) / 100) + ' MB'
#   , null, 2).join(', ')
# setInterval mem, 5000



exports.tap = (obj, fnName, fn) ->
  unless typeof obj[fnName] is 'function'
    console.log "object has no '#{fnName}' function"
    return
  orig = obj[fnName]
  obj[fnName] = ->
    fn.apply obj, arguments
    orig.apply obj, arguments