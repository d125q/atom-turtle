{ Disposable } = require 'atom'
path = require 'path'
cp = require 'child_process'

module.exports =
class Builder extends Disposable
  constructor: (turtle) ->
    @_turtle = turtle

  build: () ->
    # Check if the active editor has a `.turtle` file open.
    if !@_turtle.manager.findFiles()
      return

    # Kill any existing processes and setup the shell commands.
    @kill()
    @_setup()

    # Check if we should save prior to building.
    promise = if atom.config.get 'atom-turtle.save_on_build'
      @_save
    else
      Promise.resolve()

    # Build.
    promise.then () =>
      @_buildTimer = Date.now()
      @_turtle.logger.log = []
      @_turtle.panel.view.showLog = true
      @_turtle.package.status.view.status = 'building'
      @_turtle.package.status.view.update()
      @_run()

  _save: ->
    promises =
      for editor in atom.workspace.getTextEditors()
        if editor.isModified() and
            editor.getPath() == @turtle.paths['main']
          editor.save()
        else
          Promise.resolve()
    return Promise.all(promises)

  _run: ->
    # Get the next command in the queue.
    command = @_commands.shift()

    # If none, everything was run successfully.
    if command == undefined
      if atom.config.get 'atom-turtle.hide_log_if_successful'
        @_turtle.panel.view.showLog = false
      @_done()
      return

    # Prepare to log the output of the current command.
    @log.push ''
    @_turtle.logger.log.push
      type: 'status',
      text: "Step #{@log.length} > #{command}"

    # Execute the command.
    @_process = cp.exec(
      command, {cwd: path.dirname @_turtle.paths['main'], maxBuffer: Infinity},
      (err, stdout, stderr) =>
        @_process = undefined
        if !err or (err.code is null)
          @_run()  # Run the next command in the queue.
        else  # An error ocurred; terminate.
          @_turtle.logger.showError(
            "Failed Turtling (code #{err.code}).", err.message,
            [{
               text: "Dismiss"
               onDidClick: => @_turtle.logger.clearError()
             },
             {
               text: "Show build log"
               onDidClick: => @_turtle.logger.open()
             }]
          )
          @_turtle.parser.parse @log
          @_turtle.logger.log.push
            type: 'status',
            text: 'Error occurred while Turtling.'
          @_turtle.panel.view.update()
    )

    # Capture the stderr of the command.
    @_process.stderr.on 'data', (data) =>
      @log[@log.length - 1] += data

  _done: ->
    @_turtle.parser.parse @log
    @_turtle.logger.log.push
      type: 'status',
      text: "Successfully Turtled in #{Date.now() - @_buildTimer} ms"
    @_turtle.panel.view.update()

    # Preview if wanted.
    if atom.config.get 'atom-turtle.preview_after_build'
      @_turtle.viewer.open()

    # Clean if wanted.
    if atom.config.get 'atom-turtle.clean_after_build'
      @_turtle.cleaner.clean()

  _setup: ->
    # Run the compiler.
    @_commands.push "\"#{atom.config.get 'atom-turtle.compiler'}\"
                     \"#{@_turtle.paths['main']}\""

    # Run Ghostscript to get a PDF file and the standard output.
    ghostscript = atom.config.get 'atom-turtle.ghostscript'
    @_commands.push "\"#{ghostscript}\" -sDEVICE=pdfwrite
                     -sOutputFile=\"#{@_turtle.paths['pdf']}\"
                     -dBATCH -dNOPAUSE -dQUIET
                     -dPDFSETTINGS=/prepress
                     -sstdout=\"#{@_turtle.paths['out']}\"
                     -f \"#{@_turtle.paths['ps']}\""

  kill: ->
    # Flush the commands and kill any running process.
    @_commands = []
    @log = []
    @_process?.kill()
