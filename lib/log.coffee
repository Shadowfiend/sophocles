_ = require 'underscore'
_.str = require 'underscore.string'
_.mixin _.str.exports()

util = require 'util'
ansiColor = require './ansi-color'

global.color = (str, style) -> ansiColor.set(str, style)

global.log = (string) ->
  string += "\n" unless _(string).endsWith("\n")
  util.print "[#{color((new Date).toLocaleString(), 'blue')}] #{string}"
global.log.debug = (string) ->
  log(string) unless process.env['NODE_ENV']? && process.env['NODE_ENV'] == 'production'
global.log.error = (string) ->
  log(color(string, 'red'))
global.log.warn = (string) ->
  log(color(string, 'yellow'))

