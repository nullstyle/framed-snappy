require! fs
require! Writer: "./writer"
require! Reader: "./reader"

is-writable-mode = (mode) ->
  return true if mode.0 == 'w'
  return true if mode.1 == 'a'
  return true if mode == 'r+'
  return true if mode == 'rs+'
  false

is-readable-mode = (mode) ->
  return true if mode.0 == 'r'
  return true if mode == 'w+'
  return true if mode == 'wx+'
  return true if mode == 'a+'
  return true if mode == 'ax+'
  false


export open = (path, mode, cb) ->
  err, file <- fs.open(path, mode)
  return cb(err) if err?

  w = is-writable-mode(mode)
  r = is-readable-mode(mode)

  switch
    | w && r => return cb(new Error("No support for reading and writing from some fd"))
    | w      =>
      result = new Writer(file)
      err <- result.write-stream-id!
      return cb(err) if err?
      cb(null, result)
    | r      => 
      result = new Reader(file)
      err <- result.read-stream-id!
      return cb(err) if err?
      cb(null, result)

  
export write = (file, to-write, offset, length, cb) ->
  file.write to-write, offset, length, cb

  
export read = (file, target, offset, length, cb) ->
  file.read target, offset, length, cb

# export read-file = (path, cb) ->
#   err, {size} <- fs.stat(path)
#   return cb(err) if err?
#   err, file <- open(path, 'r')
#   return cb(err) if err?

#   results = [] 
#   read-once = () ~>


#   process.nextTick read-once

#   file.read target, offset, length, cb

export close = (file, cb) ->
  file.close cb