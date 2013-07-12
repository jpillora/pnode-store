

runner = require './lib/runner'
assert = require 'assert'

describe 'should sync data >', ->

  after ->
    console.log "DONE"

  it 'should be successful', (done) ->

    time = 5*1000

    @timeout time

    runner.run time, {
      s1: [
        ['start', 11000, []]
      ]
      s2: [
        ['in', 1,
          [
            ['start', 12000, [11000]]
            ['bucket','foo']
            # ['add', 'foo', 50]
          ]
        ]
      ]
    }, (err, results) ->
      assert.equal(1, 1);
      done()
