{_, util, utils} = require('./dependencies')

{accumQuery, reduceQueries, ctorMustImplement, protoMustImplement} = utils

class Model
  constructor: ->
  childQueryFn: (parentModel, queryFns) ->
    reduceQueries(@getFirstQuery(parentModel), queryFns)

Model.genChildQueryFn = (firstQueryFn, queryFns) ->
  (parentModel) ->
    firstQuery = firstQueryFn(parentModel)
    reduceQueries(firstQuery, queryFns)

Model.findById = (id) ->
  cacheHit = @cache.get(id)
  return cacheHit if cacheHit isnt undefined
  fetched = @batcher.by(id)
  cache.set(id, fetched)
  fetched

Model.findAsChildren = (childQueryFn, parentModel, queryExt = {}) ->
  childQueryFn(parentModel).then (query) =>
    _.extend(query, queryExt)
    @find(query)

Model.countAsChildren = (childQueryFn, parentModel, queryExt = {}) ->
  childQueryFn(parentModel).then (query) =>
    _.extend(query, queryExt)
    @count(query)

Model.distinctAsChildren = (childQueryFn, parentModel, field, queryExt) ->
  childQueryFn(parentModel).then (query) =>
    _.extend(query, queryExt)
    @distinct(field, query)

Model.genNextQueryFn = (parentId) ->
  (priorQuery) ->
    @distinctIds(priorQuery).then(@formNextQuery.bind(@))

Model.findAsParent = (parentId, childModel) ->
  @findById(childModel.get(parentId))


Model.extend = (app, name) ->
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
