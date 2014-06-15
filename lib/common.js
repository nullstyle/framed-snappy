var CRC32_SIZE, FRAME_IDS, STREAM_IDENTIFIER, out$ = typeof exports != 'undefined' && exports || this;
out$.CRC32_SIZE = CRC32_SIZE = 4;
out$.FRAME_IDS = FRAME_IDS = {
  streamId: 0xff,
  compressedData: 0x00,
  uncompressedData: 0x01,
  padding: 0xfe
};
out$.STREAM_IDENTIFIER = STREAM_IDENTIFIER = new Buffer([0xff, 0x06, 0x00, 0x00, 0x73, 0x4e, 0x61, 0x50, 0x70, 0x59]);