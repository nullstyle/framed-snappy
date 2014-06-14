var buffer, crc32c, inspect, nativeMaskedCrc, maskedCrc, maskedCrcForBuffer, bufferValid, out$ = typeof exports != 'undefined' && exports || this;
buffer = require('./buffer');
crc32c = require('fast-crc32c');
inspect = require("util").inspect;
nativeMaskedCrc = require("../../build/Release/masked_crc").nativeMaskedCrc;
out$.maskedCrc = maskedCrc = function(crc){
  var result;
  result = new Buffer(4);
  nativeMaskedCrc(crc, result);
  return result;
};
out$.maskedCrcForBuffer = maskedCrcForBuffer = function(input){
  var bufferCrc32c, result;
  bufferCrc32c = crc32c.calculate(input);
  result = new Buffer(4);
  result.writeUInt32BE(bufferCrc32c, 0);
  return maskedCrc(result);
};
out$.bufferValid = bufferValid = function(crc, input){
  return buffer.eq(crc, maskedCrcForBuffer(input));
};