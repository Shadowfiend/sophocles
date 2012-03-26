child_process = require 'child_process'
fs = require 'fs'
_ = require 'underscore'
_.str = require 'underscore.string'
_.mixin _.str.exports()
require './log'

exports.config = (callback) ->
  if global.config?
    callback(global.config)
    return

  configFiles = ['default.json']
  configFiles.push("config/#{(process.env['NODE_ENV'] || 'development')}.json")
  child_process.exec 'hostname', (error, stdout) ->
    configFiles.push "config/#{_(stdout).trim()}.json" unless error

    child_process.exec 'echo $USER', (error, stdout) ->
      configFiles.push "config/#{_(stdout).trim()}.json" unless error

      for file in configFiles
        try
          data = fs.readFileSync(file)

          try
            data = JSON.parse(data)

            if process.env['VERBOSE']
              log("Read #{color(file, 'green')}.\n")

            if global.config?
              (global.config[key] = value) for key, value of data
            else
              global.config = data
          catch error
            log.error("Failed to parse JSON for #{file}, error: #{error}")

        catch error
          if process.env['VERBOSE']
            log("Didn't find #{color(file, 'red')}.\n")

      callback(global.config)
