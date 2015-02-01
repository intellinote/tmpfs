should  = require 'should'
fs      = require 'fs'
path    = require 'path'
HOMEDIR = path.join(__dirname,'..')
LIB_COV = path.join(HOMEDIR,'lib-cov')
LIB_DIR = if fs.existsSync(LIB_COV) then LIB_COV else path.join(HOMEDIR,'lib')
Tmpfs    = require(path.join(LIB_DIR,'tmpfs')).Tmpfs

describe 'Tmpfs',->

  beforeEach (done)->
    @tmpfs = new Tmpfs()
    done()

  afterEach (done)->
    @tmpfs?.cleanup_now()
    done()

  it "can optionally create the containing directory on init",(done)->
    t = new Tmpfs(parent:@tmpfs.dir,mkdir:false)
    fs.existsSync(t.dir).should.not.be.ok
    t = new Tmpfs(parent:@tmpfs.dir,mkdir:true)
    fs.existsSync(t.dir).should.be.ok
    done()

  it "can cleanup immediately",(done)->
    t = new Tmpfs(parent:@tmpfs.dir)
    t.create_temp_file (err,f1)=>
      should.not.exist err
      fs.existsSync(f1).should.be.ok
      t.create_temp_file (err,f2)=>
        should.not.exist err
        fs.existsSync(f2).should.be.ok
        t.create_temp_file (err,f3)=>
          should.not.exist err
          fs.existsSync(f3).should.be.ok
          t.cleanup_now()
          fs.existsSync(f1).should.not.be.ok
          fs.existsSync(f2).should.not.be.ok
          fs.existsSync(f3).should.not.be.ok
          done()

  it "can create and clean up temp directories",(done)->
    t = new Tmpfs(parent:@tmpfs.dir)
    dir1 = t.make_temp_dir()
    fs.existsSync(dir1).should.be.ok
    fs.statSync(dir1).isDirectory().should.be.ok
    dir2 = t.make_temp_dir()
    fs.existsSync(dir2).should.be.ok
    fs.statSync(dir2).isDirectory().should.be.ok
    t.cleanup_now()
    fs.existsSync(dir1).should.not.be.ok
    fs.existsSync(dir2).should.not.be.ok
    done()

  it "can create filenames with given suffix or prefix",(done)->
    t = new Tmpfs(parent:@tmpfs.dir)
    path.basename(t.make_temp_filename()).should.match /^.+$/
    path.basename(t.make_temp_filename(prefix:'foo-')).should.match /^foo-.+$/
    path.basename(t.make_temp_filename(suffix:'-bar')).should.match /^.+-bar$/
    path.basename(t.make_temp_filename(prefix:'foo-',suffix:'-bar')).should.match /^foo-.+-bar$/
    done()
