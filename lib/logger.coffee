{ Disposable } = require 'atom'

module.exports =
class Logger extends Disposable
  constructor: (turtle) ->
    @_turtle = turtle
    @log = []

  showError: (title, msg, button) ->
    @clearError()
    @buildError =
      atom.notifications.addError(title, {
        detail: msg
        dismissable: true
        buttons: button
      })

  clearError: ->
    if @buildError? and !@buildError.dismissed
      @buildError.dismiss()

  open: () ->
    tmp = require 'tmp'
    fs = require 'fs'
    tmpFile = tmp.fileSync()
    fs.writeFileSync(
      tmpFile.fd, """#{@_turtle.builder.log.join("\n").trim()}"""
    )
    atom.workspace.open(tmpFile.name)
