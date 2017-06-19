{ Disposable } = require 'atom'
path = require 'path'

types =
  'error': /error(?: on line (\d+))?/i,
  'warning': /warning/i

module.exports =
class Parser extends Disposable
  constructor: (turtle) ->
    @_turtle = turtle

  parse: (log) ->
    @_turtle.package.status.view.status = 'good'
    @_parse log
    @_turtle.package.status.view.update()
    @_turtle.panel.view.update()

  _parse: (logs) ->
    items = []
    for log in logs
      for line in log.split /(?:\r?\n)+/g
        for type, regex of types
          match = line.match regex
          if match
            if match[1]?
              items.push
                type: type
                text: line
                line: parseInt match[1]
                file: @_turtle.paths['main']
            else
              items.push
                type: type
                text: line

    for type of types
      if items.map((item) -> item.type).indexOf(type) > -1
        @_turtle.package.status.view.status = type
        break

    @_turtle.logger.log = @_turtle.logger.log.concat items
