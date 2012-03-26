require 'underscore'

class CollectionManager
  constructor: (@collectionName) ->
    @collection = null
    @loadingCollection = false
    @pendingCallbacks = []

  withCollection: (callback) ->
    if @collection?
      callback @collection
    else if @loadingCollection
      @pendingCallbacks.push callback
    else
      @loadingCollection = true
      @pendingCallbacks.push callback

      db.collection @collectionName, (err, analyticsCollection) =>
        log.error err if err?

        @collection = analyticsCollection
        @loadingCollection = false
        callback @collection for callback in @pendingCallbacks

        @pendingCallbacks = []

global.CollectionManager = CollectionManager

global.cloneObject = (object) ->
  clone = {}
  clone.__proto__ = object.__proto__
  clone.prototype = object.prototype

  for key, value in object
    clone[key] = process value

global.cloneArray = (array) ->
  clone = []

  for value in array
    clone.push process(value)

process = (value) ->
  if _(value).isObject()
    cloneObject value
  else if _(value).isArray()
    cloneArray value
  else
    value
