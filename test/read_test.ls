require! framed-snappy:'../lib/index.js'
require! fs
require! should

DECOMPRESSED_LOREM_SIZE   = 894
DECOMPRESSED_LOREM_2_SIZE = DECOMPRESSED_LOREM_SIZE * 2

(...) <-! describe "framed-snappy.read"

it 'correctly decompresses', (next) ->
  err, file <- framed-snappy.open(__dirname + "/fixtures/lorem.txt.sz", 'r')
  err, bytes-read, buffer <- framed-snappy.read(file, new Buffer(5), 0, 5)
  bytes-read.should.equal 5
  buffer.toString!.should.equal "Lorem"
  next!

it 'can read a whole file', (next) ->
  err, file <- framed-snappy.open(__dirname + "/fixtures/lorem.txt.sz", 'r')
  err, bytes-read, buffer <- framed-snappy.read(file, new Buffer(1000), 0, 1000)
  bytes-read.should.equal DECOMPRESSED_LOREM_SIZE
  next!


it 'can read across frames', (next) ->
  err, file <- framed-snappy.open(__dirname + "/fixtures/lorem-2frame.txt.sz", 'r')
  err, bytes-read, buffer <- framed-snappy.read(file, new Buffer(1000), 0, 1000)
  bytes-read.should.equal 1000
  
  err, bytes-read, buffer <- framed-snappy.read(file, new Buffer(1000), 0, 1000)
  bytes-read.should.equal DECOMPRESSED_LOREM_2_SIZE - 1000
  next!

it "reads exactly the right number of bytes", (next) ->
  expected = fs.read-file-sync(__dirname + "/fixtures/lorem.txt", encoding:"utf-8")

  err, file <- framed-snappy.open(__dirname + "/fixtures/lorem.txt.sz", 'r')
  err, bytes-read, buffer <- framed-snappy.read(file, new Buffer(DECOMPRESSED_LOREM_SIZE), 0, DECOMPRESSED_LOREM_SIZE)
  bytes-read.should.equal DECOMPRESSED_LOREM_SIZE
  buffer.toString!.should.equal expected

  err, bytes-read, buffer <- framed-snappy.read(file, new Buffer(1), 0, 1)
  bytes-read.should.equal 0
  next!