fs = require 'fs'
_ = require 'underscore'
_.str = require 'underscore.string'
_.mixin _.str.exports()

STATIC_FILE_ROOT = 'public'
fileTimestampCache = {}

timestampFor = (location) ->
  timestamp = fileTimestampCache[location]
  if timestamp is undefined
    try
      timestamp = fileTimestampCache[location] =
        Number(fs.statSync("#{__dirname}/../#{STATIC_FILE_ROOT}#{location}").mtime)
    catch e
      timestamp = fileTimestampCache[location] = false

  timestamp || ''

jsTimestampFor = (location) ->
  timestamp = timestampFor("#{location}.coffee") || timestampFor("#{location}.js")

  timestamp

stylesheet = exports.stylesheet = (location) ->
  location = "#{location}.css"
  location = "/stylesheets/#{location}" unless _(location).startsWith('/')

  timestamp = timestampFor "#{location}"

  """<link rel="stylesheet" href="#{location}?#{timestamp}" />"""

script = exports.script = (location) ->
  if _(location).startsWith('/')
    """<script type="text/javascript" src="#{location}"></script>"""
  else
    location = "/javascripts/#{location}"
    timestamp = jsTimestampFor location

    """<script type="text/javascript" src="#{location}.js?#{timestamp}"></script>"""

ieCommentStart = exports.ieCommentStart = (ieVersionString) ->
  "<!--[if #{ieVersionString || 'IE'}]>"

ieCommentEnd = exports.ieCommentEnd = () ->
  "<![endif]-->"

exports.withHtmlHelpers = (locals) ->
  locals.stylesheet = stylesheet
  locals.script = script
  locals.ieCommentStart = ieCommentStart
  locals.ieCommentEnd = ieCommentEnd

  locals
