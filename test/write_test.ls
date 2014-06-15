require! framed-snappy:'../lib/index.js'
require! fs
require! should

require! "../lib/util/buffer"

DECOMPRESSED_LOREM_SIZE   = 894
DECOMPRESSED_LOREM_2_SIZE = DECOMPRESSED_LOREM_SIZE * 2

(...) <-! describe "framed-snappy.write"

before-each (done) ->
  err <- fs.unlink __dirname + "/../tmp/lorem.txt.sz"
  done!

it 'correctly compresses', (next) ->
  err, uncompressed           <- fs.read-file(__dirname + "/fixtures/lorem.txt")
  err, file                   <- framed-snappy.open(__dirname + "/../tmp/lorem.txt.sz", 'w')
  err, bytes-written, b       <- framed-snappy.write(file, uncompressed, 0, uncompressed.length)
  err                         <- framed-snappy.close(file)

  err, actual   <- fs.read-file(__dirname + "/fixtures/lorem.txt.sz")
  err, expected <- fs.read-file(__dirname + "/../tmp/lorem.txt.sz")

  is-same = buffer.eq actual, 0, expected, 0, actual.length
  is-same.should.be.true

  next! 

# it 'can write a file with multiple frames'
# it 'writes a frame uncompressed when the compressed form is larger', (next) ->
#   err, uncompressed           <- fs.read-file(__dirname + "/fixtures/doggy.gif")
#   err, file                   <- framed-snappy.open(__dirname + "/../tmp/doggy.gif.sz", 'w')
#   err, bytes-written, b       <- framed-snappy.write(file, uncompressed, 0, uncompressed.length)
#   err                         <- framed-snappy.close(file)

#   err, actual   <- fs.read-file(__dirname + "/fixtures/doggy.gif.sz")
#   err, expected <- fs.read-file(__dirname + "/../tmp/doggy.gif.sz")

#   is-same = buffer.eq actual, 0, expected, 0, actual.length
#   is-same.should.be.true

#   next! 
