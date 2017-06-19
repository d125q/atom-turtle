{ Disposable } = require 'atom'
path = require 'path'
fs = require 'fs'
glob = require 'glob'

module.exports =
class Cleaner extends Disposable
  constructor: (turtle) ->
    @_turtle = turtle

  clean: ->
    if !@_turtle.manager.findFiles()
      return

    root = path.dirname @_turtle.paths['main']
    removeGlobs = atom.config.get('atom-turtle.extensions_to_clean')
      .replace(/\s/, '').split(',')

    for removeGlob in removeGlobs
      glob(removeGlob, cwd: root, (err, files) ->
        if err
          return
        for file in files
          fs.unlink(path.resolve(root, file))
      )
