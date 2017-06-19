{ Disposable } = require 'atom'
http = require 'http'
ws = require 'ws'
fs = require 'fs'
path = require 'path'

module.exports =
class Server extends Disposable
  constructor: (turtle) ->
    @_turtle = turtle

    # Create the HTTP server.
    @http = http.createServer (request, response) =>
      @_handler(request, response)
    @_root = "#{path.dirname __filename}/../viewer"

    # Listen for connections.
    new Promise (resolve, reject) =>
      @http.listen 0, 'localhost', undefined, (err) ->
        if err
          reject(err)

    # Create the WebSocket server.
    wss = ws.createServer server: @http
    wss.on 'connection', (ws) =>
      ws.on 'message', (msg) => @_turtle.viewer.handler(ws, msg)
      ws.on 'close',   ()    => @_turtle.viewer.handler(ws, '{"type": "close"}')

  _handler: (request, response) ->
    # Check if we should load the viewer.
    if request.url.indexOf('viewer.html') > -1
      response.writeHead 200, 'Content-Type': 'text/html'
      response.end fs.readFileSync("#{@_root}/viewer.html"), 'utf-8'
      return

    # Check if we should load the PDF.
    if request.url.indexOf('preview.pdf') > -1
      size = fs.statSync(@_turtle.paths['pdf']).size
      response.writeHead 200,
        'Content-Type': 'application/pdf',
        'Content-Length': size
      fs.createReadStream(@_turtle.paths['pdf']).pipe(response)
      return

    # Some other request.
    file = path.join @_root, request.url.split('?')[0]
    switch path.extname file
      when '.js'
        contentType = 'text/javascript'
      when '.css'
        contentType = 'text/css'
      when '.json'
        contentType = 'application/json'
      when '.png'
        contentType = 'image/png'
      when '.jpg'
        contentType = 'image/jpg'
      else
        contentType = 'text/html'

    fs.readFile file, (err, content) ->
      if err
        if err.code == 'ENOENT'
          response.writeHead 404
        else
          response.writeHead 500
        response.end()
      else
        response.writeHead 200, 'Content-Type': contentType
        response.end content, 'utf-8'
