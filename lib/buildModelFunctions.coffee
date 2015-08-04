{_} = require('./dependencies')

genFindAsChildren = (childQueryFn, childModel) ->
  findAsChildren = (parentInstance, queryExt = {}) ->
    childQueryFn(parentInstance).then (query) ->
      _.extend(query, queryExt)
      childModel.find(query)

genCountAsChildren = (childQueryFn, childModel) ->
  countAsChildren = (parentInstance, queryExt = {}) ->
    childQueryFn(parentInstance).then (query) ->
      _.extend(query, queryExt)
      childModel.count(query)

genDistinctAsChildren = (childQueryFn, childModel) ->
  distinctAsChildren = (parentInstance, field, queryExt) ->
    childQueryFn(parentInstance).then (query) ->
      _.extend(query, queryExt)
      childModel.distinct(field, query)

genFirstQueryFn = ({parentId}) ->
  firstQueryFn = (parentInstance) ->
    query = {}
    query[parentId] = parentInstance.getId()
    query

genNextQueryFn = ({parentId, child, parent}) ->
  nextQueryFn = (priorQueryPromise) ->
    Promise.resolve(priorQueryPromise).then (priorQuery) ->
      child.distinctIds(priorQuery).then (vals) ->
        query = {}
        query[parentId] = {"$in": vals}
        query

accumQuery = (query, queryFn) -> queryFn(query)

genChildQueryFn = (firstQueryFn, otherQueryFns) ->
  (parentInstance) ->
    otherQueryFns.reduce(accumQuery, firstQueryFn(parentInstance))


buildModelFunctions = (models) ->
  _.forEach models, (model) ->
    _.forEach model.relationships.parent, (parentRelationship, parentName) ->
      [firstLink, otherLinks...] = parentRelationship.links
      firstQueryFn = genFirstQueryFn(firstLink)
      otherQueryFns = otherLinks.map(genNextQueryFn)
      childQueryFn = genChildQueryFn(firstQueryFn, otherQueryFns)
      model.findAsChildrenFns[parentName] = genFindAsChildren(childQueryFn, model)
      model.countAsChildrenFns[parentName] = genCountAsChildren(childQueryFn, model)
      model.distinctAsChildrenFns[parentName] = genDistinctAsChildren(childQueryFn, model)


module.exports = buildModelFunctions
