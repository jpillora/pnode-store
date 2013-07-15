

runner = require './lib/runner'
assert = require 'assert'

describe 'should sync data >', ->

  it 'should be successful', (done) ->

    @timeout 5*1000

    runner.run {
      s1:
        start: [11000, []],
        wait1:
          create: ['foo']
          insert: ['foo', 5]
          wait3:
            report: []
      s2: 
        start: [12000, [11000]],  
        create: ['foo']
        wait4:
          report: []

    }, (err, results) ->
      assert.equal(1, 1);
      done()
