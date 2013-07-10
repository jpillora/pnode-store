# store data in a JSON file


    # @tmpDir = path.join process.cwd(), 'tmp'
    # @dataFile = path.join @tmpDir, 'data.json'

    # @_persist = _.debounce @_persist, options.persistDelay or 5000

bucket =
  _persist: ->
    json = JSON.stringify @data
    return if json is @_persisted
    fs.writeFile @dataFile, json, (err) =>
      if err
        @log "error persisting data store: #{err}"
      else
        @log "data store persisted"
        @_persisted = json

  _restore: ->
    mkdirp.sync @tmpDir
    return null unless fs.existsSync @dataFile
    json = fs.readFileSync @dataFile
    return unless json
    try
      data = JSON.parse json
      @log "data store restored"
      @_persisted = json
      return data
    catch e

    return null