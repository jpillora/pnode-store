module.exports = class Base
  name: "Base"
  toString: ->
    '' + (@store or '') + @name + (if @id then ': ' + @id else '') + ': '
  err: (str) ->
    throw new Error "#{@}#{str}"
  log: ->
    return unless @store.opts.debug
    console.log.apply console, [@toString()].concat Array::slice.call arguments