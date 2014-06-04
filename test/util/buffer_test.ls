require! should

describe "buffer.eq", (...) -> 
  {eq} = require("../../lib/util/buffer")

  it 'detects equality', ->
    l = new Buffer([0x00, 0x01])
    r = new Buffer([0x00, 0x01])
    eq(l, 0, r, 0, 2).should.equal true


  it 'detects in-equality', ->
    l = new Buffer([0x00, 0x01])
    r = new Buffer([0x00, 0x02])
    eq(l, 0, r, 0, 2).should.equal false

  it 'only compares regions specified in the params', ->
      l = new Buffer([0x00, 0x01])
      r = new Buffer([0x00, 0x02, 0x00])
      eq(l, 0, r, 0, 1).should.equal true
      eq(l, 0, r, 2, 1).should.equal true

describe "get-buffer-of-size", (...) ->
  {get-buffer-of-size} = require("../../lib/util/buffer")

  it "maintains size if more space is not needed", ->
    buffer = new Buffer(4)
    buffer = get-buffer-of-size(buffer, 2)
    buffer.length.should.equal 4

  it "increases size if more space is not needed", ->
    buffer = new Buffer(4)
    buffer = get-buffer-of-size(buffer, 5)
    buffer.length.should.equal 5

  it "copies content into the new buffer", ->
    buffer = new Buffer([0x01])
    buffer = get-buffer-of-size(buffer, 2)
    buffer[0].should.equal 0x01
