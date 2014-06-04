var getBufferOfSize, eq, out$ = typeof exports != 'undefined' && exports || this;
out$.getBufferOfSize = getBufferOfSize = function(buffer, size){
  var result;
  if (buffer.length >= size) {
    return buffer;
  }
  result = new Buffer(size);
  buffer.copy(result, 0);
  return result;
};
out$.eq = eq = function(l, l_offset, r, r_offset, length){
  var i$, i;
  for (i$ = 0; i$ < length; ++i$) {
    i = i$;
    if (l[l_offset + i] !== r[r_offset + i]) {
      return false;
    }
  }
  return true;
};