fs     = require 'fs'
{exec} = require 'child_process'

task 'package', 'Convert package.coffee to package.json', ->
  exec "coffee --compile --bare package.coffee", (err, stdout, stderr) ->
    throw err if err
    pkgInfo = require './package.js'
    fs.writeFileSync('package.json', JSON.stringify(pkgInfo, null, 2))
    exec "rm package.js"
