require! should
require! "../../lib/util/buffer"


describe "masked-crc", (...) -> 
  {masked-crc} = require("../../lib/util/crc")

  it 'should work', ->
    test-crc = (input, output) ->
      actual = masked-crc(new Buffer(input))
      expected = new Buffer(output)
      buffer.eq(actual, 0, expected, 0, 4).should.equal(true)

    test-crc [0xc9, 0x03, 0x57, 0x11], [0xde, 0x7c, 0xa6, 0x50]