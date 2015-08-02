{Promise} = require('./dependencies')

class Query
  constructor: ->
    @ids = []
    @deferreds = {}
    setTimeout(@run.bind(@), @wait)

  run: ->
    @batcher.query = null
    @getList(@ids)
      .then        => deferred.resolve()   for id, deferred of @deferreds
      .catch (err) => deferred.reject(err) for id, deferred of @deferreds

  by: (id) ->
    unless @deferreds[id]
      @ids.push(id)
      @deferreds[id] = Promise.pending()
    @deferreds[id].promise


class Batcher
  constructor: (getList, @wait = 0) ->
    thisBatcher = @
    @query = null

    class BatchedQuery extends Query
      batcher: thisBatcher
      getList: getList
      wait: wait

    @Query = BatchedQuery

  by: (id) ->
    @query ?= new this.Query(@)
    @query.by(id)


module.exports = Batcher
