require! "./buffer"
require! crc32c:"fast-crc32c"
{inspect} = require "util"
{native-masked-crc} = require "../../build/Release/masked_crc"

export masked-crc = (crc) ->
  result  = new Buffer(4)
  native-masked-crc crc, result
  result

export masked-crc-for-buffer = (input) ->
  buffer-crc32c = crc32c.calculate(input)
  result  = new Buffer(4)
  result.writeUInt32BE(buffer-crc32c, 0)
  masked-crc result

export buffer-valid = (crc, input) -> 
  buffer.eq(crc, masked-crc-for-buffer(input))