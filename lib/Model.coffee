{_, utils} = require('./dependencies')

{accumQuery, reduceQueries, ctorMustImplement, protoMustImplement} = utils

class Model
  constructor: (@app, @name, opts) ->
    @batcher = new this.Batcher(@)
    @cache = @app.caches.new(@name)
    @findAsChildrenFns = {}
    @findPriorParentFns = {}
    @countAsChildrenFns = {}
    @distinctAsChildrenFns = {}
    @parentIds = {}
    @relationships = {child: {}, parent: {}}

  childQueryFn: (parentModel, queryFns) ->
    reduceQueries(@getFirstQuery(parentModel), queryFns)

  genChildQueryFn: (firstQueryFn, queryFns) ->
    (parentModel) ->
      firstQuery = firstQueryFn(parentModel)
      reduceQueries(firstQuery, queryFns)

  findById: (id) ->
    cacheHit = @cache.get(id)
    return cacheHit if cacheHit isnt undefined
    fetched = @batcher.by(id)
    cache.set(id, fetched)
    fetched

  findAsChildren: (childQueryFn, parentModel, queryExt = {}) ->
    childQueryFn(parentModel).then (query) =>
      _.extend(query, queryExt)
      @find(query)

  countAsChildren: (childQueryFn, parentModel, queryExt = {}) ->
    childQueryFn(parentModel).then (query) =>
      _.extend(query, queryExt)
      @count(query)

  distinctAsChildren: (childQueryFn, parentModel, field, queryExt) ->
    childQueryFn(parentModel).then (query) =>
      _.extend(query, queryExt)
      @distinct(field, query)

  genNextQueryFn: (parentId) ->
    (priorQuery) ->
      @distinctIds(priorQuery).then(@formNextQuery.bind(@))

  findAsParent: (parentId, childModel) ->
    @findById(childModel.get(parentId))



protoMustImplement(
  Model, 'Batcher', 'ModelInstance', 'count', 'distinct', 'distinctIds', 'find',
    'formNextQuery', 'getAppearsAs', 'getParentIds', 'getFields',
    'createInstance'
)





module.exports = Model
