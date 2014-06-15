require! snappy
require! fs
{map, sum} = require("prelude-ls")
{get-buffer-of-size} = require("./util/buffer")
{masked-crc-for-buffer} = require("./util/crc")

{CRC32_SIZE, FRAME_IDS, STREAM_IDENTIFIER} = require("./common")
FRAME_HEADER_SIZE  = 4

TARGET_FRAME_SIZE  = 5 * 1024 * 1024 # 5MB
USEABLE_FRAME_SIZE = TARGET_FRAME_SIZE - FRAME_HEADER_SIZE

write-stream-id = (file, cb) ->
  err, bytes-written, buffer <- fs.write file, STREAM_IDENTIFIER, 0, STREAM_IDENTIFIER.length, null
  cb err

write-chunk-id = (output, type) ->
  output.writeUInt8 FRAME_IDS[type], 0

write-chunk-length = (output, length) ->
  get-octet = (octet, num) ->
    to-shift = octet * 8
    num .>>. to-shift .&. 0xff

  output[1] = get-octet(0, length)
  output[2] = get-octet(1, length)
  output[3] = get-octet(2, length)

write-chunk-data = (output, input) ->
  input.copy output, 8

write-crc = (output, crc) ->
  crc.copy output, 4 

write-compressed-chunk = (output, crc, compressed-data) ->
  write-chunk-id     output, "compressedData" 
  write-chunk-length output, CRC32_SIZE + compressed-data.length
  write-crc          output, crc
  write-chunk-data   output, compressed-data


class Writer
  (@file) ->
    @queued_buffers = []

  _queued-to-write: ->
    sum @queued_buffers.map (.length)

  _finish-frame: (cb) ->
    to-write = new Buffer(@_queued-to-write!)
    
    offset = 0
    for i til @queued_buffers.length
      qb = @queued_buffers[i]
      qb.copy to-write, offset, 0, qb.length
      offset += qb.length


    crc = masked-crc-for-buffer to-write

    err, compressed-data <~ snappy.compress to-write
    return cb(err) if err?

    output-buffer-size = FRAME_HEADER_SIZE + CRC32_SIZE + compressed-data.length
    to-write = new Buffer(output-buffer-size)

    write-compressed-chunk to-write, crc, compressed-data 
    
    err, bytes-written, buffer <~ fs.write @file, to-write, 0, output-buffer-size, null
    return cb(err) if err?

    if bytes-written < output-buffer-size
      return cb(new Error("couldn't write enough bytes #output-buffer-size wanted, #bytes-written written")) 

    @queued_buffers = []
    cb!

  close: (cb) ->
    return if @closed
    @closed = true
    err <~ @_finish-frame
    return cb(err) if err?
    err <~ fs.close @file
    cb(err)


  write: (to-write, offset, length, cb) ->
    to-push = if typeof(to-write) == "string"
      new Buffer(to-write) 
    else
      to-queue = new Buffer(length)
      to-write.copy to-queue, 0, offset, length
      to-queue

    @queued_buffers.push to-push

    if @_queued-to-write! > TARGET_FRAME_SIZE
      err <~ @_finish-frame!
      return cb(err) if err?
      cb null, length, to-push
    else
      cb null, length, to-push

  write-stream-id: (cb) ->
    write-stream-id @file, cb


module.exports = Writer

