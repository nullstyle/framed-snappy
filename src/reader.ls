require! snappy
require! fs: "fs-ext"
require! "./util/crc"

{eq:buffer-eq} = require("./util/buffer")

{CRC32_SIZE, FRAME_IDS, STREAM_IDENTIFIER} = require("./common")

read-chunk-id = (input) ->
  type = input[0]

read-chunk-length = (input) ->
  input[1] .|. input[2] .<<. 8 .|. input[3] .<<. 16



class Reader
  (@file) ->
    @decompressed-buffer      = null
    @decompressed-buffer-read = null

  _read-compressed-frame: (length, cb) ->
    err, bytes-read, buffer <~ fs.read(@file, new Buffer(length), 0, length, null)
    switch
    | err?                => cb(err)
    | bytes-read < length => cb(new Error("Expected to read #length bytes, but read #bytes-read"))
    | otherwise           =>
      err, @decompressed-buffer <~ snappy.decompress buffer, snappy.parsers.raw
      return cb(err) if err?
      @decompressed-buffer-read = 0
      cb!
  _read-uncompressed-frame: (length, cb) ->
    err, bytes-read, buffer <~ fs.read(@file, new Buffer(length), 0, length, null)
    switch
    | err?                => cb(err)
    | bytes-read < length => cb(new Error("Expected to read #length bytes, but read #bytes-read"))
    | otherwise           =>
      @decompressed-buffer = buffer
      @decompressed-buffer-read = 0
      cb!

  _read-crc: (cb) ->
    err, bytes-read, buffer <~ fs.read(@file, new Buffer(4), 0, 4, null)
    switch
    | err?           => cb(err)
    | bytes-read < 4 => cb(new Error("Expected to read 4 bytes, but read #bytes-read"))
    | otherwise      => 
      @decompressed-crc = buffer
      cb!

  _validate-crc: (cb) ->
    if crc.buffer-valid(@decompressed-crc, @decompressed-buffer)
      cb!
    else
      cb(new Error("Invalid CRC in frame"))

  _read-header: (cb) ->
    err, bytes-read, buffer <~ fs.read(@file, new Buffer(4), 0, 4, null)

    switch
    | err?           => cb(err)
    | bytes-read == 0 => cb!
    | bytes-read < 4 => cb(new Error("Expected to read 4 bytes, but read #bytes-read"))
    | otherwise      => 
      type   = read-chunk-id buffer
      length = read-chunk-length buffer
      cb null, type, length

  _read-next-frame: (cb) ->
    err, type, length <~ @_read-header
    switch
    | err? => cb(err)
    | !type? => 
      cb null, true
    | type == FRAME_IDS["compressedData"] =>
      length -= CRC32_SIZE
      err <~ @_read-crc 
      return cb(err) if err?
      err <~ @_read-compressed-frame length
      return cb(err) if err?
      err <~ @_validate-crc
      return cb(err) if err?
      cb null, false
    | type == FRAME_IDS["uncompressedData"] =>
      length -= CRC32_SIZE
      err <~ @_read-crc 
      return cb(err) if err?
      err <~ @_read-uncompressed-frame length
      return cb(err) if err?
      err <~ @_validate-crc
      return cb(err) if err?
      cb null, false
    | otherwise =>
      # skip the frame by advancing the file
      err <~ fs.seek @file, length, 1
      @_read-next-frame(cb)

  _available-bytes-in-frame: ->
    return 0 if !@decompressed-buffer?
    @decompressed-buffer.length - @decompressed-buffer-read

  _bytes-i-can-read: (desired-length) ->
    available-bytes = @_available-bytes-in-frame!
    if available-bytes < desired-length
      available-bytes
    else
      desired-length

  close: (cb) ->
    return if @closed
    @closed = true
    err <~ fs.close @file
    cb(err)

  read-stream-id: (cb) ->
    err, bytes-read, buffer <- fs.read(@file, new Buffer(STREAM_IDENTIFIER.length), 0, STREAM_IDENTIFIER.length, null)
    switch
    | err? => 
      cb err
    | bytes-read < STREAM_IDENTIFIER.length =>
      cb(new Error("Expected to read #{STREAM_IDENTIFIER.length} bytes, but read #bytes-read"))
    | !buffer-eq(STREAM_IDENTIFIER, 0, buffer, 0, STREAM_IDENTIFIER.length) =>
      cb(new Error("Stream-id not correct"))
    | otherwise =>
      cb!

  read: (buffer, offset, length, cb) ->
    total-read = 0

    read-once = (offset, length) ~> 
      available-bytes = @_bytes-i-can-read(length)
      if available-bytes > 0
        @decompressed-buffer.copy(buffer, offset, @decompressed-buffer-read, available-bytes)

      @decompressed-buffer-read += available-bytes
      
      next-offset = offset + available-bytes
      next-length = length - available-bytes
      total-read += available-bytes

      switch
      | next-length == 0 => cb null, total-read, buffer
      | @no-more-frames  => cb null, total-read, buffer
      | otherwise        =>
        err, @no-more-frames <~ @_read-next-frame!
        return cb(err) if err?
        setImmediate -> read-once(next-offset, next-length)

    read-once(offset, length)

module.exports = Reader
    