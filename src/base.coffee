
_ = require("lodash")

module.exports = class Base
  name: "Base"
  toString: ->
    "#{@store or ''}#{@name}: "
  err: (str) ->
    throw new Error "#{@}#{str}"
  log: ->
    return unless @store.debug
    console.log.apply console, [@toString()].concat _.toArray arguments