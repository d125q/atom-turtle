{ Disposable } = require 'atom'
fs = require 'fs'
path = require 'path'
chokidar = require 'chokidar'

module.exports =
class Manager extends Disposable
  constructor: (turtle) ->
    @_turtle = turtle

  @_isTurtleFile: (name) ->
    return path.extname(name) == '.turtle'

  @_replaceExtension: (filePath, oldExt, newExt) ->
    path.join(
      path.dirname(filePath),
      path.basename(filePath, oldExt) + newExt
    )

  findFiles: ->
    # Check if the active editors has a `.turtle` file in it.
    editor = atom.workspace.getActivePaneItem()
    currentPath = editor?.buffer?.file?.path

    if currentPath and @constructor._isTurtleFile(currentPath)
      @_turtle.paths =
        'main': currentPath
        'pdf': @constructor._replaceExtension(currentPath, '.turtle', '.pdf')
        'ps':  @constructor._replaceExtension(currentPath, '.turtle', '.ps')
        'out': @constructor._replaceExtension(currentPath, '.turtle', '.out')
      return true

    return false
