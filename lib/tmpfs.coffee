path   = require 'path'
fs     = require 'fs'
os     = require 'os'
temp   = require 'temp'
mkdirp = require 'mkdirp'
remove = require 'remove'

class Tmpfs

  # OPTIONS:
  #  - `dir` - the parent directory that will contain temp files and sub-directories (optional, defaults to a dir below `os.tmpDir()`).
  #  - `app_name` - used in the name of the containing directory (unless `dir` is specified); (optional, defaults to `tmpfs`).
  #  - `mkdir` - unless `false`, immediately make the directory to hold temp files
  #  - `cleanup_on_exit` - unless `false`, automatically remove the container `dir` on exit
  constructor:(options={})->
    app_name = options.app_name ? 'tmpfs'
    parent = options.parent ? os.tmpDir()
    @dir = options.dir ? path.join(parent,@_random_name(app_name))
    unless options.mkdir is false
      @_mkdir @dir
    unless options.cleanup_on_exit is false
      @_on_exit => @cleanup_now(false)

  # Generate a unique file *name* within the parent directory.
  make_temp_filename:(options={})=>
    options.dir ?= @dir
    return temp.path(options)

  # Create a temporary directory within th e parent directory.
  make_temp_dir:(options={})=>
    options.dir ?= @dir
    return temp.mkdirSync(options)

  # Remove the parent directory and all contained files right now.
  # If `remake_dir` is true, the dir will be recreated (leaving an empty directory).
  cleanup_now:(remake_dir=false)=>
    @_rmdir(@dir)
    if remake_dir
      _mkdir(@dir)

  # Create a new temporary file and open it for writing (fd).
  # Callback signature: (err, filename, file_descriptor)
  open_temp_file:(options={},callback)=>
    if not callback? and typeof options is 'function'
      callback = options
      options  = {}
    options.dir ?= @dir
    return temp.open options, (err, map)=>
      callback(err,map?.path,map?.fd)

  # Create a new temporary file.
  # Callback signature: (err, filename)
  create_temp_file:(options={},callback)=>
    if not callback? and typeof options is 'function'
      callback = options
      options  = {}
    options.dir ?= @dir
    return temp.open options, (err, map)=>
      if err?
        callback(err)
      else
        fs.close map.fd, ()=>
          callback(null,map.path)

  # Create a new temporary file and open it for writing (stream).
  # Callback signature: (err, filename, stream)
  open_temp_stream:(options={},callback)=>
    if not callback? and typeof options is 'function'
      callback = options
      options  = {}
    options.dir ?= @dir
    filename = @make_temp_filename()
    stream = fs.createWriteStream(filename)
    callback(err,filename,stream)

  # Generate a random, probably unique filename, using the given prefix and suffix if specified.
  _random_name:(prefix,suffix)=>
    if prefix?
      prefix = "#{prefix}-"
    else
      prefix = ''
    if suffix?
      suffix = "-#{suffix}"
    else
      suffix = ''
    "#{prefix}#{Date.now()}-#{process.pid}-#{(Math.random()*4294967296).toString(36)}-#{(Math.random()*4294967296).toString(36)}#{suffix}"

  # Remove the given file.
  _rm:(file)=>
    try
      fs.unlinkSync(file)
    catch e
      # ignored

  # Remove the given directory.
  _rmdir:(dir)=>
    try
      remove.removeSync(dir)
    catch e
      # ignored

  # Create the given directory.
  _mkdir:(dir)=>mkdirp.sync(dir)

  # Register `callback` as a method to invoke on exit.
  _on_exit:(callback)=>
    process.on 'cleanup', ()->
      callback()
    process.on 'exit', ()->
      process.emit 'cleanup'
    process.on 'SIGINT', ()->
      process.exit 2
    process.on 'uncaughtException', (e)->
      console.log "uncaughtException", e, e.stack
      process.exit 99

exports.tmpfs = exports.Tmpfs = Tmpfs
