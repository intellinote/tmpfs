path   = require 'path'
fs     = require 'fs'
os     = require 'os'
temp   = require 'temp'
mkdirp = require 'mkdirp'
remove = require 'remove'

class Tmpfs

  constructor:(options={})->
    app_name = options.app_name ? 'tmpfs'
    @dir = options.dir ? path.join(os.tmpDir(),"#{app_name}-#{Date.now()}-#{Math.round(Math.random()*10000)}")
    unless options.mkdir is false
      @_mkdir @dir
    unless options.cleanup_on_exit is false
      @_on_exit => @cleanup_now(false)

  make_temp_filename:(options={})=>
    options.dir ?= @dir
    return temp.path(options)

  cleanup_now:(remake_dir=false)=>
    _rmdir(@dir)
    if remake_dir
      _mkdir(@dir)

  _rm:(file)=>fs.unlinkSync(file)
  _rmdir:(dir)=>remove.removeSync(dir)
  _mkdir:(dir)=>mkdirp.sync(dir)

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
