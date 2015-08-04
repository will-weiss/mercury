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
    @findAsChildrenFns = {}
    @findPriorParentFns = {}
    @countAsChildrenFns = {}
    @distinctAsChildrenFns = {}
    @parentIds = {}
    @relationships = {child: {}, parent: {}}

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
    cache.set(id, fetched)
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

  genNextQueryFn: (parentId) ->
    (priorQuery) ->
      @distinctIds(priorQuery).then(@formNextQuery.bind(@))

  findAsParent: (parentId, childInstance) ->
    @findById(childInstance.get(parentId))

  createInstance: ->
    new this.ModelInstance(@)



protoMustImplement(
  Model, 'Batcher', 'ModelInstance', 'count', 'distinct', 'distinctIds', 'find',
    'formNextQuery', 'getAppearsAs', 'getParentIds', 'getFields'
)





module.exports = Model
