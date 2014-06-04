CRC_MASK = 0xa282ead8

export masked-crc = (unmasked-crc) ->
  val     = unmasked-crc.readUInt32BE(0)
  new-val = (val .>>. 15) .|. (val .<<. 17) + CRC_MASK
  result = new Buffer(4)
  result.writeInt32BE(new-val, 0)
  result
