{_, utils} = require('./dependencies')

{accumQuery, reduceQueries, ctorMustImplement, protoMustImplement} = utils

class Model
  constructor: (opts) ->
    @opts = _.extend(opts, @opts)
    _.defaults(@opts, {wait: 0})
    @batcher = new this.constructor.Batcher(@opts.wait)

  findById: (id) ->
    cacheHit = @cache.get(id)
    return cacheHit if cacheHit isnt undefined
    fetched = @batcher.by(id)
    cache.set(id, fetched)
    fetched

  getFirstQuery: (parentId) ->
    query = {}
    query[parentId] = @getId()
    query

  childQueryFn: (parentModel, queryFns) ->
    reduceQueries(@getFirstQuery(parentModel), queryFns)

  findAsChildren: (childQueryFn, parentModel, queryExt = {}) ->
    childQueryFn(parentModel).then (query) =>
      _.extend(query, queryExt)
      @constructor.find(query)

  countAsChildren: (childQueryFn, parentModel, queryExt = {}) ->
    childQueryFn(parentModel).then (query) =>
      _.extend(query, queryExt)
      @constructor.count(query)

  distinctAsChildren: (childQueryFn, parentModel, field, queryExt) ->
    childQueryFn(parentModel).then (query) =>
      _.extend(query, queryExt)
      @constructor.distinct(field, query)

  nextQueryFn: (parentId, priorQuery) ->
    @constructor.distinctIds(priorQuery).then(@formNextQuery.bind(@))

  findAsParent: (parentId, childModel) ->
    @constructor.findById(childModel.get(parentId))


ctorMustImplement(
  Model, 'Batcher', 'count', 'distinct', 'distinctIds', 'find', 'formNextQuery'
)

protoMustImplement(Model, )


module.exports = Model
