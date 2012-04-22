path = require 'path'
fs = require 'fs'
coffee = require 'coffee-script'

csPathForFilename = (filename) ->
  "#{__dirname}/../public/javascripts/#{filename}.coffee"

renderCoffeeFile = (request, response) ->
  fs.readFile csPathForFilename(request.params.file), 'utf-8', (err, coffeeScript) ->
    if err?
      response.send "Error producing file #{request.params.file}: #{err}."
    else
      compiled = coffee.compile coffeeScript

      response.send compiled, { 'Content-Type': 'text/javascript' }

tryRenderCoffeeFile = (request, response, next) ->
  path.exists csPathForFilename(request.params.file), (exists) ->
    if exists
      renderCoffeeFile(request, response)
    else
      next()

exports.setUpRoutes = (app) ->
  app.get '/javascripts/:file.js', tryRenderCoffeeFile
