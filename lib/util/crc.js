var CRC_MASK, maskedCrc, out$ = typeof exports != 'undefined' && exports || this;
CRC_MASK = 0xa282ead8;
out$.maskedCrc = maskedCrc = function(unmaskedCrc){
  var val, newVal, result;
  val = unmaskedCrc.readUInt32BE(0);
  newVal = val >> 15 | (val << 17) + CRC_MASK;
  result = new Buffer(4);
  result.writeInt32BE(newVal, 0);
  return result;
};