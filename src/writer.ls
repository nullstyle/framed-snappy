


write-stream-id = (file, cb) ->
  err, bytes-written, buffer <- fs.write file, STREAM_IDENTIFIER, 0, STREAM_IDENTIFIER.length, null

write-chunk-id = (output, type) ->
  output.writeUInt8 FRAME_IDS[type], 0

write-chunk-length = (output, length) ->
  get-octet = (octet, num) ->
    to-shift = num * 8
    num .>>. to-shift .&. 0xff

  output[1] = get-octet(0, length)
  output[2] = get-octet(1, length)
  output[3] = get-octet(2, length)

write-chunk-data = (output, input) ->
  input.copy output, 8

write-crc = (output, crc) ->
  # TODO: write the crc

write-compressed-chunk = (output, crc, compressed-data) ->
  write-chunk-id     output, "compressedData" 
  write-chunk-length output, CRC32_SIZE + compressed-data.length
  write-crc          output, crc
  write-chunk-data   output, compressed-data


class Writer
  (@file) ->
    @output-buffer          = new Buffer TARGET_FRAME_SIZE
    @current-buffer         = new Buffer TARGET_FRAME_SIZE
    @current-buffered-bytes = 0

  _finish-frame: (cb) ->
    to-write = new Buffer(@current-buffered-bytes)
    @current-buffer.copy to-write, 0, 0, to-write.length

    err, compressed-data <~ snappy.compress @current-buffer
    return cb(err) if err?

    output-buffer-size = FRAME_HEADER_SIZE + CRC32_SIZE + compressed-data.length
    @output-buffer = get-buffer-of-size @output-buffer, output-buffer-size

    console.log "u:#{@current-buffered-bytes} c:#{compressed-data.length}"

    # TODO: crc the @current-buffer
    write-compressed-chunk @output-buffer, 0, compressed-data 
    
    err, bytes-written, buffer <~ fs.write @file, @output-buffer, 0, output-buffer-size, null
    return cb(err) if err?

    if bytes-written < output-buffer-size
      return cb(new Error("couldn't write enough bytes #output-buffer-size wanted, #bytes-written written")) 

    @current-buffered-bytes = 0
    cb!

  close: (cb) ->
    return if @closed
    @closed = true
    err <~ @_finish-frame
    return cb(err) if err?
    err <~ fs.close @file
    cb(err)


  write: (to-write, offset, length, cb) ->
    to-write = new Buffer(to-write) if typeof(to-write) == "string"

    buffer-size-needed = @current-buffered-bytes + length
    @current-buffer    = get-buffer-of-size @current-buffer, buffer-size-needed

    to-write.copy @current-buffer, @current-buffered-bytes, offset, length
    @current-buffered-bytes += length

    if @current-buffered-bytes > TARGET_FRAME_SIZE
      err <~ @_finish-frame!
      return cb(err) if err?
      cb null, length, @current-buffer
    else
      cb null, length, @current-buffer

module.exports = Writer

