###
Module dependencies.
###
eyes = require 'eyes'

eyes.inspect __dirname

configReader = require "./lib/config-reader"

# Libraries
express = require 'express'
mongo = require 'mongodb'
# Internal utilities
util = require 'util'
utils = require './lib/utils'
# Rendering modules
blog = require './lib/blog'
renderingModules = [blog]

# App-wide HTML helpers.
htmlTimestampHelpers = require './lib/html-timestamp-helpers'

# Logging, set up as global functions.
require './lib/log'

app = module.exports = express.createServer()
[Db, Server, BSON] = [mongo.Db, mongo.Server, mongo.BSONPure]

process.on 'uncaughtException', (exception) ->
  log.error 'Uncaught Exception'
  log.error exception
  log.error exception.stack

log.debug 'Reading config...'
configReader.config ->
  mongoConfig = global.config.mongo
  client = new Db mongoConfig.db, new Server(mongoConfig.host, mongoConfig.port, {})
  global.db = null

  log.debug "Connecting to mongo db #{mongoConfig.db} at #{mongoConfig.host}:#{mongoConfig.port}..."
  client.open (err, openDb) ->
    log.error err if err?

    global.db = openDb # make this a global variable for now; should probably move to an accessor

    log.debug 'Setting up Express app...'
    # Configuration
    app.configure ->
      app.set 'views', __dirname + '/views'
      app.set 'view engine', 'jade'

      app.use express.bodyParser()
      app.use express.methodOverride()
      app.use express.cookieParser()
      app.use express.session({ secret: 'blog that git' })
      app.use express.compiler({ src: __dirname + '/public', enable: ['coffeescript'] })
      app.use app.router
      app.use express.static(__dirname + '/public')

    app.configure 'development', ->
      app.use express.errorHandler({ dumpExceptions: true, showStack: true })
    app.configure 'production', ->
      app.use express.errorHandler()

    app.helpers htmlTimestampHelpers

    log.debug 'Setting up routes...'
    module.setUpRoutes app for module in renderingModules

    log.debug 'Looking up posts collection...'
    db.collection 'posts', (err, postsCollection) ->
      log.error err if err?
      blog.setPostsCollection postsCollection

      log.debug 'Looking up message collection...'
      db.collection 'chatMessages', (err, messageCollection) ->
        log.error err if err?

        #chat.setupChatRoom messageCollection, feedItemCollection
        #feed.setFeedItemCollection feedItemCollection

        log.debug "Running app on port #{config.port}..."
        # Only listen when executed directly.
        unless module.parent
          app.listen config.port
          log "Express server listening on port #{app.address().port}"

        log.debug "Setting up memory usage monitoring..."
        setInterval((-> log.debug(util.inspect(process.memoryUsage()))), 10000)
