var writeStreamId, writeChunkId, writeChunkLength, writeChunkData, writeCrc, writeCompressedChunk, Writer;
writeStreamId = function(file, cb){
  return fs.write(file, STREAM_IDENTIFIER, 0, STREAM_IDENTIFIER.length, null, function(err, bytesWritten, buffer){});
};
writeChunkId = function(output, type){
  return output.writeUInt8(FRAME_IDS[type], 0);
};
writeChunkLength = function(output, length){
  var getOctet;
  getOctet = function(octet, num){
    var toShift;
    toShift = num * 8;
    return num >> toShift & 0xff;
  };
  output[1] = getOctet(0, length);
  output[2] = getOctet(1, length);
  return output[3] = getOctet(2, length);
};
writeChunkData = function(output, input){
  return input.copy(output, 8);
};
writeCrc = function(output, crc){};
writeCompressedChunk = function(output, crc, compressedData){
  writeChunkId(output, "compressedData");
  writeChunkLength(output, CRC32_SIZE + compressedData.length);
  writeCrc(output, crc);
  return writeChunkData(output, compressedData);
};
Writer = (function(){
  Writer.displayName = 'Writer';
  var prototype = Writer.prototype, constructor = Writer;
  function Writer(file){
    this.file = file;
    this.outputBuffer = new Buffer(TARGET_FRAME_SIZE);
    this.currentBuffer = new Buffer(TARGET_FRAME_SIZE);
    this.currentBufferedBytes = 0;
  }
  prototype._finishFrame = function(cb){
    var toWrite, this$ = this;
    toWrite = new Buffer(this.currentBufferedBytes);
    this.currentBuffer.copy(toWrite, 0, 0, toWrite.length);
    return snappy.compress(this.currentBuffer, function(err, compressedData){
      var outputBufferSize;
      if (err != null) {
        return cb(err);
      }
      outputBufferSize = FRAME_HEADER_SIZE + CRC32_SIZE + compressedData.length;
      this$.outputBuffer = getBufferOfSize(this$.outputBuffer, outputBufferSize);
      console.log("u:" + this$.currentBufferedBytes + " c:" + compressedData.length);
      writeCompressedChunk(this$.outputBuffer, 0, compressedData);
      return fs.write(this$.file, this$.outputBuffer, 0, outputBufferSize, null, function(err, bytesWritten, buffer){
        if (err != null) {
          return cb(err);
        }
        if (bytesWritten < outputBufferSize) {
          return cb(new Error("couldn't write enough bytes " + outputBufferSize + " wanted, " + bytesWritten + " written"));
        }
        this$.currentBufferedBytes = 0;
        return cb();
      });
    });
  };
  prototype.close = function(cb){
    var this$ = this;
    if (this.closed) {
      return;
    }
    this.closed = true;
    return this._finishFrame(function(err){
      if (err != null) {
        return cb(err);
      }
      return fs.close(this$.file, function(err){
        return cb(err);
      });
    });
  };
  prototype.write = function(toWrite, offset, length, cb){
    var bufferSizeNeeded, this$ = this;
    if (typeof toWrite === "string") {
      toWrite = new Buffer(toWrite);
    }
    bufferSizeNeeded = this.currentBufferedBytes + length;
    this.currentBuffer = getBufferOfSize(this.currentBuffer, bufferSizeNeeded);
    toWrite.copy(this.currentBuffer, this.currentBufferedBytes, offset, length);
    this.currentBufferedBytes += length;
    if (this.currentBufferedBytes > TARGET_FRAME_SIZE) {
      return this._finishFrame(function(err){
        if (err != null) {
          return cb(err);
        }
        return cb(null, length, this$.currentBuffer);
      });
    } else {
      return cb(null, length, this.currentBuffer);
    }
  };
  return Writer;
}());
module.exports = Writer;