{utils, Promise} = require('./dependencies')

class Query
  constructor: (@batcher) ->
    @ids = []
    @deferreds = {}
    setTimeout(@run.bind(@), @batcher.wait)

  resolveOne: (result) ->
    id = @batcher.Model.getId(result)
    deferred = @deferreds[id]
    delete @deferreds[id]
    deferred.resolve(result)

  run: ->
    @batcher.query = null
    @batcher.getList.call(@, @ids)
      .then        => deferred.resolve()   for id, deferred of @deferreds
      .catch (err) => deferred.reject(err) for id, deferred of @deferreds

  by: (id) ->
    console.log("BATCHING ID: #{id}")
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


utils.mustImplement(Batcher, 'getList')

module.exports = Batcher
