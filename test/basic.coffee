

runner = require './lib/runner'
{expect} = require "chai"
_ = require 'lodash'

describe '1. simple >', ->

  #start both, insert 5 random, check
  it '1. 500ms waits >', (done) ->
    @timeout 5*1000
    runner.run {
      s1:
        start: [51000, []]
        create: ['foo']
        'wait500ms':
          insert: ['foo', 5]
          'wait500ms':
            report: []
      s2: 
        start: [52000, [51000]], 
        create: ['foo']
        'wait500ms':
          insert: ['foo', 5]
          'wait500ms':
            report: []
    }, (err, results) ->
      expect(results).to.have.length(2)
      expect(results[0]).to.deep.equal(results[1])
      done()

  #start both, insert 5 random, check
  it '2. 200ms waits >', (done) ->
    @timeout 5*1000
    runner.run {
      s1:
        start: [51000, []]
        create: ['foo']
        'wait200ms':
          insert: ['foo', 5]
          'wait200ms':
            report: []
      s2: 
        start: [52000, [51000]], 
        create: ['foo']
        'wait200ms':
          insert: ['foo', 5]
          'wait200ms':
            report: []
    }, (err, results) ->
      expect(results).to.have.length(2)
      expect(results[0]).to.deep.equal(results[1])
      done()
