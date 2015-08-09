{utils, Promise} = require('./dependencies')

# A query which maintains ids to fetch and the deferred promises of each. Runs
# after a timer has expired.
class Query
  constructor: (@batcher) ->
    @ids = []
    @deferreds = {}
    setTimeout(@run.bind(@), @batcher.wait)

  # Resolve a single result by resolving and deleting the reference to its
  # corresponding deferred promise.
  resolveOne: (result) ->
    id = @batcher.Model.getId(result)
    deferred = @deferreds[id]
    delete @deferreds[id]
    deferred.resolve(result)

  # Run a query by executing the getList function of the batcher. When all
  # results have been fetched, resolve extant deferred promises with undefined.
  # Reject all deferred promises with any error.
  run: ->
    @batcher.query = null
    @batcher.getList.call(@, @ids)
      .then        => deferred.resolve()   for id, deferred of @deferreds
      .catch (err) => deferred.reject(err) for id, deferred of @deferreds

  # Return a deferred promise for the supplied id, adding the id to the array of
  # those to be fetched if it is not yet present.
  by: (id) ->
    unless @deferreds[id]
      @ids.push(id)
      @deferreds[id] = Promise.pending()
    @deferreds[id].promise


# Batches findById requests for a model. Returns promises for individual
# requests. A query is run to fetch batched ids after a timer has expired.
class Batcher
  constructor: (@Model, @wait = 0) ->
    @query = null

  # Creates a query if one does not already exist. The id is added to the query.
  by: (id) ->
    @query ?= new Query(@)
    @query.by(id)

# The prototype of a Batcher must implement a getList function.
utils.mustImplement(Batcher, 'getList')

module.exports = Batcher
