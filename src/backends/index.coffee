
fs = require 'fs'
path = require 'path'

backends = {}

#expected interface
exports.props = 
  'async':'boolean'
  'get':'function'
  'getAll':'function'
  'set':'function'
  'del':'function'

exports.add = (name, obj) ->

  if typeof obj.create isnt 'function'
    throw "Backend must implement create"

  if /[^a-z]/.test name
    throw "Backend name must be lowercase letters only"

  if exports.get name
    throw "Backend '#{name}' already exists"

  backends[name] = obj
  true

exports.get = (name) ->
  return backends[name]

#init
fs.readdirSync(__dirname).forEach (file) ->
  if file isnt 'index.js'
    exports.add file.replace('.js',''), require("./#{file}")
