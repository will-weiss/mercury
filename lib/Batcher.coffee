{utils, Promise} = require('./dependencies')

class Query
  constructor: (@batcher) ->
    @ids = []
    @deferreds = {}
    setTimeout(@run.bind(@), @batcher.wait)

  resolveOne: (result) ->
    deferred = @deferreds[result._id]
    delete @deferreds[result._id]
    deferred.resolve(result)

  run: ->
    @batcher.query = null
    @batcher.getList.call(@, @ids)
      .then        => deferred.resolve()   for id, deferred of @deferreds
      .catch (err) => deferred.reject(err) for id, deferred of @deferreds

  by: (id) ->
    unless @deferreds[id]
      @ids.push(id)
      @deferreds[id] = Promise.pending()
    @deferreds[id].promise


class Batcher
  constructor: (@Model, @wait = 0) ->
    @query = null

  by: (id) ->
    @query ?= new Query(@)
    @query.by(id)


utils.protoMustImplement(Batcher, 'getList')

module.exports = Batcher
