_ = require "lodash"
{EventEmitter} = require "events"

Base = class Base extends EventEmitter
  name: "Base"
  toString: ->
    @name + (if @id then ': ' + @id else '') + ':'
  err: (str) ->
    throw new Error "#{@}#{str}"
  log: ->
    return unless @store.opts.debug
    console.log.apply console, [@toString()].concat Array::slice.call arguments

Base.mixin = (obj) ->
  #also extend base
  _.extend obj::, _.pick Base::, 'log', 'err', 'toString'

module.exports = Base