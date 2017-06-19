module.exports =
  config: require './config'

  activate: ->
    { CompositeDisposable } = require 'atom'
    @disposables = new CompositeDisposable
    @activated = false
    global.atom_turtle = this
    @disposables.add atom.workspace.observeTextEditors (editor) =>
      return if @activated
      editor.observeGrammar (grammar) =>
        if grammar.packageName is 'atom-turtle' or
            grammar.scopeName.indexOf('source.turtle') > -1 or
            grammar.name is 'Turtle'
          new Promise (resolve, reject) =>
            @lazyLoad()
            resolve()

  lazyLoad: ->
    return if @activated
    @activated = true
    @turtle = new Turtle
    @turtle.package = this
    @disposables.add @turtle

    @disposables.add atom.commands.add 'atom-workspace',
      'atom-turtle:build': () => @turtle.builder.build()
      'atom-turtle:preview': () => @turtle.viewer.open()
      'atom-turtle:clean': () => @turtle.cleaner.clean()
      'atom-turtle:kill': () => @turtle.builder.kill()
      'atom-turtle:toggle-panel': () => @turtle.panel.toggle()

    path = require 'path'
    @disposables.add atom.workspace.observeTextEditors (editor) =>
      @disposables.add editor.onDidSave () =>
        if atom.config.get 'atom-turtle.build_after_save' and \
            editor.buffer.file?.path
          if @turtle.manager.isTurtleFile(editor.buffer.file?.path)
            @turtle.builder.build()

  deactivate: ->
    @turtle?.dispose()
    @disposables.dispose()

  consumeStatusBar: (statusBar) ->
    if !@status?
      Status = require './view/status'
      @status = new Status
      @disposables.add @status
    @status.attach statusBar
    { Disposable } = require 'atom'
    return new Disposable( => @status.detach())

class Turtle
  constructor: ->
    { CompositeDisposable } = require 'atom'
    @disposables = new CompositeDisposable
    Builder = require './builder'
    Cleaner = require './cleaner'
    Manager = require './manager'
    Server = require './server'
    Viewer = require './viewer'
    Parser = require './parser'
    Panel = require './view/panel'
    Logger = require './logger'

    @builder = new Builder(this)
    @cleaner = new Cleaner(this)
    @manager = new Manager(this)
    @viewer = new Viewer(this)
    @server = new Server(this)
    @parser = new Parser(this)
    @panel = new Panel(this)
    @logger = new Logger(this)

    @disposables.add @builder, @cleaner, @manager, @server, @viewer, @parser,
                     @panel, @logger

  dispose: ->
    @disposables.dispose()
