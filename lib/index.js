var fs, Writer, Reader, isWritableMode, isReadableMode, open, write, read, close, out$ = typeof exports != 'undefined' && exports || this;
fs = require('fs');
Writer = require('./writer');
Reader = require('./reader');
isWritableMode = function(mode){
  if (mode[0] === 'w') {
    return true;
  }
  if (mode[1] === 'a') {
    return true;
  }
  if (mode === 'r+') {
    return true;
  }
  if (mode === 'rs+') {
    return true;
  }
  return false;
};
isReadableMode = function(mode){
  if (mode[0] === 'r') {
    return true;
  }
  if (mode === 'w+') {
    return true;
  }
  if (mode === 'wx+') {
    return true;
  }
  if (mode === 'a+') {
    return true;
  }
  if (mode === 'ax+') {
    return true;
  }
  return false;
};
out$.open = open = function(path, mode, cb){
  return fs.open(path, mode, function(err, file){
    var w, r, result;
    if (err != null) {
      return cb(err);
    }
    w = isWritableMode(mode);
    r = isReadableMode(mode);
    switch (false) {
    case !(w && r):
      return cb(new Error("No support for reading and writing from some fd"));
    case !w:
      return result = new Writer(file);
    case !r:
      result = new Reader(file);
      return result.readStreamId(function(err){
        if (err != null) {
          return cb(err);
        }
        return cb(null, result);
      });
    }
  });
};
out$.write = write = function(file, toWrite, offset, length, cb){
  return file.write(toWrite, offset, length, cb);
};
out$.read = read = function(file, target, offset, length, cb){
  return file.read(target, offset, length, cb);
};
out$.close = close = function(file, cb){
  return file.close(cb);
};