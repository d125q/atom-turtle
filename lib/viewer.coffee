{ Disposable } = require 'atom'
fs = require 'fs'
path = require 'path'

module.exports =
class Viewer extends Disposable
  constructor: (turtle) ->
    @_turtle = turtle
    @_client = {}
    @_items = {}

  handler: (ws, msg) ->
    data = JSON.parse msg
    switch data.type
      when 'open'
        @_client.ws?.close()
        @_client.ws = ws
      when 'loaded'
        if @_client.position and @_client.ws?
          @_client.ws.send JSON.stringify @_client.position
      when 'position'
        @_client.position = data
      when 'close'
        @_client.ws = undefined

  _title: ->
    "Turtle: #{path.basename @_turtle.paths['pdf']}"

  open: ->
    @_open()
    @_client.ws?.send JSON.stringify type: 'refresh'

  _open: ->
    # Check if the active editor has a `.turtle` file open.
    if !@_turtle.manager.findFiles()
      return

    # Make sure that everything is OK.
    if !fs.existsSync(@_turtle.paths['pdf']) or
       !fs.existsSync(@_turtle.paths['out']) or
       !@_getUrl()
      return

    pane = atom.workspace.getActivePane()

    if @_items['pdf'] and atom.workspace.paneForItem(@_items['pdf'])?
      atom.workspace.paneForItem(@_items['pdf']).activateItem(@_items['pdf'])
    else
      @_items['pdf'] = new PDFView(@_url, @_title())
      atom.workspace.getActivePane().splitRight().addItem(@_items['pdf'])

    if @_items['out']? and atom.workspace.paneForItem(@_items['out'])?
      atom.workspace.paneForItem(@_items['out']).activateItem(@_items['out'])
    else
      pane.activate()
      atom.workspace.open(@_turtle.paths['out'], {'split': 'down'})
        .then (item) =>
          @_items['out'] = item
          pane.activate()

  _getUrl: ->
    try
      { address, port } = @_turtle.server.http.address()
      @_url = """http://#{address}:#{port}/viewer.html?file=preview.pdf"""
    catch err
      return false
    return true

class PDFView
  constructor: (url, title) ->
    @_element = document.createElement 'iframe'
    @_element.setAttribute 'src', url
    @_element.setAttribute 'width', '100%'
    @_element.setAttribute 'height', '100%'
    @_element.setAttribute 'frameborder', 0
    @_title = title

  getTitle: ->
    return @_title

  getElement: ->
    return @_element

  serialize: ->
    return @_element.getAttribute 'src'

  destroy: ->
    @_element.remove()
