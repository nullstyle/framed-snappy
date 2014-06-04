var snappy, fs, bufferEq, FRAME_HEADER_SIZE, CRC32_SIZE, TARGET_FRAME_SIZE, USEABLE_FRAME_SIZE, STREAM_IDENTIFIER, FRAME_IDS, readChunkId, readChunkLength, readCrc, Reader;
snappy = require('snappy');
fs = require('fs-ext');
bufferEq = require("./util/buffer").eq;
FRAME_HEADER_SIZE = 4;
CRC32_SIZE = 4;
TARGET_FRAME_SIZE = 5 * 1024 * 1024;
USEABLE_FRAME_SIZE = TARGET_FRAME_SIZE - FRAME_HEADER_SIZE;
STREAM_IDENTIFIER = new Buffer([0xff, 0x06, 0x00, 0x00, 0x73, 0x4e, 0x61, 0x50, 0x70, 0x59]);
FRAME_IDS = {
  streamId: 0xff,
  compressedData: 0x00,
  uncompressedData: 0x01,
  padding: 0xfe
};
readChunkId = function(input){
  var type;
  return type = input[0];
};
readChunkLength = function(input){
  return input[1] | input[2] << 8 | input[3] << 16;
};
readCrc = function(input){
  return input[4] | input[5] << 8 | input[6] << 16 | input[7] << 24;
};
Reader = (function(){
  Reader.displayName = 'Reader';
  var prototype = Reader.prototype, constructor = Reader;
  function Reader(file){
    this.file = file;
    this.decompressedBuffer = null;
    this.decompressedBufferRead = null;
  }
  prototype._readCompressedFrame = function(length, cb){
    var this$ = this;
    console.log("reading compressed frame");
    console.log(length);
    return fs.read(this.file, new Buffer(length), 0, length, null, function(err, bytesRead, buffer){
      switch (false) {
      case err == null:
        return cb(err);
      case !(bytesRead < length):
        return cb(new Error("Expected to read " + length + " bytes, but read " + bytesRead));
      default:
        return snappy.decompress(buffer, snappy.parsers.raw, function(err, decompressedBuffer){
          this$.decompressedBuffer = decompressedBuffer;
          if (err != null) {
            return cb(err);
          }
          this$.decompressedBufferRead = 0;
          return cb();
        });
      }
    });
  };
  prototype._readCrc = function(cb){
    var this$ = this;
    return fs.read(this.file, new Buffer(4), 0, 4, null, function(err, bytesRead, buffer){
      var crc;
      switch (false) {
      case err == null:
        return cb(err);
      case !(bytesRead < 4):
        return cb(new Error("Expected to read 4 bytes, but read " + bytesRead));
      default:
        crc = readCrc(buffer);
        console.log("frame-crc: " + crc);
        return cb(null, crc);
      }
    });
  };
  prototype._readHeader = function(cb){
    var this$ = this;
    return fs.read(this.file, new Buffer(4), 0, 4, null, function(err, bytesRead, buffer){
      var type, length;
      switch (false) {
      case err == null:
        return cb(err);
      case bytesRead !== 0:
        return cb();
      case !(bytesRead < 4):
        return cb(new Error("Expected to read 4 bytes, but read " + bytesRead));
      default:
        type = readChunkId(buffer);
        length = readChunkLength(buffer);
        console.log("frame-type: " + type);
        console.log("frame-length: " + length);
        return cb(null, type, length);
      }
    });
  };
  prototype._readNextFrame = function(cb){
    var this$ = this;
    return this._readHeader(function(err, type, length){
      switch (false) {
      case err == null:
        return cb(err);
      case type != null:
        console.log("no more frames");
        return cb(null, true);
      case type !== FRAME_IDS["compressedData"]:
        length -= CRC32_SIZE;
        return this$._readCrc(function(err, crc){
          if (err != null) {
            return cb(err);
          }
          return this$._readCompressedFrame(length, function(err){
            if (err != null) {
              return cb(err);
            }
            return cb(null, false);
          });
        });
      default:
        console.log("otherwise: " + err + ", " + type + ", " + length);
        return fs.seek(this$.file, length, 1, function(err){
          return this$._readNextFrame(cb);
        });
      }
    });
  };
  prototype._availableBytesInFrame = function(){
    if (this.decompressedBuffer == null) {
      return 0;
    }
    return this.decompressedBuffer.length - this.decompressedBufferRead;
  };
  prototype._bytesICanRead = function(desiredLength){
    var availableBytes;
    availableBytes = this._availableBytesInFrame();
    if (availableBytes < desiredLength) {
      return availableBytes;
    } else {
      return desiredLength;
    }
  };
  prototype.close = function(cb){
    var this$ = this;
    if (this.closed) {
      return;
    }
    this.closed = true;
    return fs.close(this.file, function(err){
      return cb(err);
    });
  };
  prototype.readStreamId = function(cb){
    return fs.read(this.file, new Buffer(STREAM_IDENTIFIER.length), 0, STREAM_IDENTIFIER.length, null, function(err, bytesRead, buffer){
      switch (false) {
      case err == null:
        return cb(err);
      case !(bytesRead < STREAM_IDENTIFIER.length):
        return cb(new Error("Expected to read " + STREAM_IDENTIFIER.length + " bytes, but read " + bytesRead));
      case !!bufferEq(STREAM_IDENTIFIER, 0, buffer, 0, STREAM_IDENTIFIER.length):
        return cb(new Error("Stream-id not correct"));
      default:
        return cb();
      }
    });
  };
  prototype.read = function(buffer, offset, length, cb){
    var totalRead, readOnce, this$ = this;
    totalRead = 0;
    readOnce = function(offset, length){
      var availableBytes, nextOffset, nextLength;
      console.log("reading " + length + " at " + offset);
      availableBytes = this$._bytesICanRead(length);
      if (availableBytes > 0) {
        this$.decompressedBuffer.copy(buffer, offset, this$.decompressedBufferRead, availableBytes);
      }
      console.log("copied " + availableBytes + " at " + offset);
      this$.decompressedBufferRead += availableBytes;
      nextOffset = offset + availableBytes;
      nextLength = length - availableBytes;
      totalRead += availableBytes;
      switch (false) {
      case nextLength !== 0:
        return cb(null, totalRead, buffer);
      case !this$.noMoreFrames:
        return cb(null, totalRead, buffer);
      default:
        console.log("loading another frame");
        return this$._readNextFrame(function(err, noMoreFrames){
          this$.noMoreFrames = noMoreFrames;
          console.log(err + " : " + this$.noMoreFrames);
          if (err != null) {
            return cb(err);
          }
          return setImmediate(function(){
            return readOnce(nextOffset, nextLength);
          });
        });
      }
    };
    return readOnce(offset, length);
  };
  return Reader;
}());
module.exports = Reader;