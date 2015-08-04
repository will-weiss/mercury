{_, utils} = require('./dependencies')

{accumQuery, reduceQueries, ctorMustImplement, protoMustImplement} = utils

class Model
  constructor: ->
    @batcher = new this.Batcher(@)

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


extend: (app, name) ->
  ThisModel = @
  class Model extends ThisModel
  Model.registeredAs = name
  Model.cache = app.caches.new(Model, name)
  Model.batcher = new ThisModel.Batcher(Model)
  Model.findAsChildrenFns = {}
  Model.findPriorParentFns = {}
  Model.countAsChildrenFns = {}
  Model.distinctAsChildrenFns = {}
  Model.parentIds = {}
  Model.relationships = {child: {}, parent: {}}
  Model


ctorMustImplement(
  Model, 'Batcher', 'count', 'distinct', 'distinctIds', 'find', 'formNextQuery',
    'getAppearsAs', 'getParentIds', 'getFields'
)

protoMustImplement(Model, 'get', 'getId', 'getQuery')


module.exports = Model
