export get-buffer-of-size = (buffer, size) ->
  return buffer if buffer.length >= size
  result = new Buffer size
  buffer.copy result, 0
  result

export eq = (l, l_offset, r, r_offset, length) ->
  for i til length
    return false if l[l_offset + i] != r[r_offset + i]
  true


