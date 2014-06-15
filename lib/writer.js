var snappy, fs, ref$, map, sum, getBufferOfSize, maskedCrcForBuffer, CRC32_SIZE, FRAME_IDS, STREAM_IDENTIFIER, FRAME_HEADER_SIZE, TARGET_FRAME_SIZE, USEABLE_FRAME_SIZE, writeStreamId, writeChunkId, writeChunkLength, writeChunkData, writeCrc, writeCompressedChunk, Writer;
snappy = require('snappy');
fs = require('fs');
ref$ = require("prelude-ls"), map = ref$.map, sum = ref$.sum;
getBufferOfSize = require("./util/buffer").getBufferOfSize;
maskedCrcForBuffer = require("./util/crc").maskedCrcForBuffer;
ref$ = require("./common"), CRC32_SIZE = ref$.CRC32_SIZE, FRAME_IDS = ref$.FRAME_IDS, STREAM_IDENTIFIER = ref$.STREAM_IDENTIFIER;
FRAME_HEADER_SIZE = 4;
TARGET_FRAME_SIZE = 5 * 1024 * 1024;
USEABLE_FRAME_SIZE = TARGET_FRAME_SIZE - FRAME_HEADER_SIZE;
writeStreamId = function(file, cb){
  return fs.write(file, STREAM_IDENTIFIER, 0, STREAM_IDENTIFIER.length, null, function(err, bytesWritten, buffer){
    return cb(err);
  });
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
writeCrc = function(output, crc){
  return crc.copy(output, 4);
};
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
    this.queued_buffers = [];
  }
  prototype._queuedToWrite = function(){
    return sum(this.queued_buffers.map(function(it){
      return it.length;
    }));
  };
  prototype._finishFrame = function(cb){
    var toWrite, offset, i$, to$, i, qb, crc, this$ = this;
    toWrite = new Buffer(this._queuedToWrite());
    offset = 0;
    for (i$ = 0, to$ = this.queued_buffers.length; i$ < to$; ++i$) {
      i = i$;
      qb = this.queued_buffers[i];
      qb.copy(toWrite, offset, 0, qb.length);
      offset += qb.length;
    }
    crc = maskedCrcForBuffer(toWrite);
    return snappy.compress(toWrite, function(err, compressedData){
      var outputBufferSize, toWrite;
      if (err != null) {
        return cb(err);
      }
      outputBufferSize = FRAME_HEADER_SIZE + CRC32_SIZE + compressedData.length;
      toWrite = new Buffer(outputBufferSize);
      writeCompressedChunk(toWrite, crc, compressedData);
      return fs.write(this$.file, toWrite, 0, outputBufferSize, null, function(err, bytesWritten, buffer){
        if (err != null) {
          return cb(err);
        }
        if (bytesWritten < outputBufferSize) {
          return cb(new Error("couldn't write enough bytes " + outputBufferSize + " wanted, " + bytesWritten + " written"));
        }
        this$.queued_buffers = [];
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
    var toPush, toQueue, this$ = this;
    toPush = typeof toWrite === "string"
      ? new Buffer(toWrite)
      : (toQueue = new Buffer(length), toWrite.copy(toQueue, 0, offset, length), toQueue);
    this.queued_buffers.push(toPush);
    if (this._queuedToWrite() > TARGET_FRAME_SIZE) {
      return this._finishFrame(function(err){
        if (err != null) {
          return cb(err);
        }
        return cb(null, length, toPush);
      });
    } else {
      return cb(null, length, toPush);
    }
  };
  prototype.writeStreamId = function(cb){
    return writeStreamId(this.file, cb);
  };
  return Writer;
}());
module.exports = Writer;