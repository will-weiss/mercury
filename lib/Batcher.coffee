{utils, Promise} = require('./dependencies')

# A query which maintains ids to fetch and the deferred promises of each. Runs
# on the next tick of the event loop, after the ids have been collected.
class Query
  constructor: ->
    @ids = []
    @deferreds = {}
    process.nextTick(@run.bind(@))

  # Resolve a single result by resolving and deleting the reference to its
  # corresponding deferred promise.
  onData: (result) ->
    id = @Model.getId(result)
    deferred = @deferreds[id]
    delete @deferreds[id]
    deferred.resolve(result)

  # Run a query by executing the getList function of the batcher. When all
  # results have been fetched, resolve extant deferred promises with undefined.
  # Reject all deferred promises with any error.
  run: ->
    @batcher.query = null
    @Model.findByIds(@ids, @onData.bind(@))
      .then        => deferred.resolve()   for id, deferred of @deferreds
      .catch (err) => deferred.reject(err) for id, deferred of @deferreds

  # Return a deferred promise for the supplied id, adding the id to the array of
  # those to be fetched if it is not yet present.
  by: (id) ->
    unless @deferreds[id]
      @ids.push(id)
      @deferreds[id] = Promise.pending()
    @deferreds[id].promise


# Batches findById requests for a model querying the collected ids as a unit
# while resolving the requests individually.
class Batcher
  constructor: (Model) ->
    class @Query extends Query
    @Query::batcher = @
    @Query::Model = Model
    @query = null

  # Creates a query if one does not already exist. The id is added to the query.
  by: (id) ->
    @query ?= new @Query()
    @query.by(id)


module.exports = Batcher
