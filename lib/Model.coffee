{_, i, utils} = require('./dependencies')

{pluralize} = i()

{accumQuery, reduceQueries, ctorMustImplement, protoMustImplement} = utils

class Model
  constructor: (@app, @name, @opts={}) ->

  init: ->
    @batcher = new this.Batcher(@)
    @cache = @app.caches.new(@name)
    {@appearsAsSingular, @appearsAsPlural} = @opts
    # Get how the model appears as a singular if not otherwise specified.
    @appearsAsSingular ||= @getAppearsAs()
    # Get how the model appears as a plural if not otherwise specified.
    @appearsAsPlural ||= pluralize(@appearsAsSingular)
    @relationships = {child: {}, parent: {}}
    @parentIdFields = {}
    @fields = null
    @objectType = null

  childQueryFn: (parentInstance, queryFns) ->
    reduceQueries(@getFirstQuery(parentInstance), queryFns)

  genChildQueryFn: (firstQueryFn, queryFns) ->
    (parentInstance) ->
      firstQuery = firstQueryFn(parentInstance)
      reduceQueries(firstQuery, queryFns)

  findById: (id) ->
    cacheHit = @cache.get(id)
    return cacheHit if cacheHit isnt undefined
    fetched = @batcher.by(id)
    @cache.set(id, fetched)
    fetched

  findAsChildren: (childQueryFn, parentInstance, queryExt = {}) ->
    childQueryFn(parentInstance).then (query) =>
      _.extend(query, queryExt)
      @find(query)

  countAsChildren: (childQueryFn, parentInstance, queryExt = {}) ->
    childQueryFn(parentInstance).then (query) =>
      _.extend(query, queryExt)
      @count(query)

  distinctAsChildren: (childQueryFn, parentInstance, field, queryExt) ->
    childQueryFn(parentInstance).then (query) =>
      _.extend(query, queryExt)
      @distinct(field, query)

  genNextQueryFn: (parentIdField) ->
    (priorQuery) ->
      @distinctIds(priorQuery).then(@formNextQuery.bind(@))

  findAsParent: (parentIdField, childInstance) ->
    @findById(childInstance.get(parentIdField))


protoMustImplement(
  Model, 'Batcher', 'ModelInstance', 'count', 'distinct', 'distinctIds', 'find',
    'formNextQuery', 'getAppearsAs', 'getParentIdFields', 'getFields'
)


module.exports = Model
