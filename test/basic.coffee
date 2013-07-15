

runner = require './lib/runner'
{expect} = require "chai"
_ = require 'lodash'

check = (results, numServers, nameBucket, numEntries) ->
  expect(results).to.have.length(numServers)
  first = null
  #check each server
  for result in results
    bucket = result[nameBucket]
    expect(bucket).to.be.an('object')
    expect(Object.keys(bucket)).to.have.length(numEntries)
    if first is null
      first = result
    else
      expect(result).to.deep.equal(first)

describe '1. simple >', ->

  #start both, insert 5 random, check
  xit '1. 1s waits >', (done) ->
    @timeout 5*1000
    runner.run {
      s1:
        start: [51000, []]
        create: ['foo']
        'wait2s':
          insert: ['foo', 5000]
          'wait1500ms':
            report: []
      s2: 
        start: [52000, [51000]],
        create: ['foo']
        'wait2s':
          insert: ['foo', 5000]
          'wait1500ms':
            report: []
    }, (err, results) ->
      check results, 2, 'foo', 10000
      done()

  #start both, insert 5 random, check
  it '2. 200ms waits >', (done) ->
    @timeout 5*1000
    runner.run {
      s1:
        start: [54000, []]
        create: ['bar']
        'wait200ms':
          insert: ['bar', 5]
          'wait200ms':
            report: []
      s2: 
        start: [55000, [54000]], 
        create: ['bar']
        'wait200ms':
          insert: ['bar', 15]
          'wait200ms':
            report: []

    }, (err, results) ->
      check results, 2, 'bar', 20
      done()


describe '2. catch-up >', ->

  #start one, insert 50, start other, check
  xit '1. 500ms waits >', (done) ->
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
        'wait500ms':
          start: [52000, [51000]],
          create: ['foo']
          'wait500ms':
            report: []
    }, (err, results) ->
      check results, 2, 'foo', 5
      done()


