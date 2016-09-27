fs     = require 'fs'
{exec} = require 'child_process'

task 'package', 'Convert package.coffee to package.json', ->
  exec "coffee --compile --bare package.coffee", (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
    pkgInfo = require './package.js'
    fs.writeFileSync('package.json', JSON.stringify(pkgInfo, null, 2))
    exec "rm package.js"

task 'build', 'Build the .js files', (options) ->
  console.log('Compiling Coffee from src')
  compile = (dest) ->
    mv '-f', "static/javascripts/#{dest}.js", "static/javascripts/#{dest}.uncompressed.js"
#    makeUgly "static/javascripts/#{dest}.uncompressed.js", "static/javascripts/#{dest}.js"
#    exec "rm static/javascripts/#{dest}.uncompressed.js"
  exec "coffee --compile --output ./ src/server", (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
#  exec "coffee --compile --output static/javascripts src/client", (err, stdout, stderr) ->
#    throw err if err
#    console.log stdout + stderr
#    compile file[0...file.lastIndexOf('.')] for file in ls('src/client')