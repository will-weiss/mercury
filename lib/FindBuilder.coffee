{_} = DEPENDENCIES

dbFunctions = {}
prettyPluralMap = {}

getColl = (m) -> m?.constructor?.collection?.name ||
  (throw new Error("#{m} is not a known model"))

genFindAsChildren = (childQueryFn, childModel) ->
  return findAsChildren = (parentModel, queryExt = {}, select, opts) ->
    childQueryFn(parentModel).then (query) ->
      _.extend(query, queryExt)
      childModel.findQ(query, select, opts)

genCountAsChildren = (childQueryFn, childModel) ->
  return countAsChildren = (parentModel, queryExt = {}) ->
    childQueryFn(parentModel).then (query) ->
      _.extend(query, queryExt)
      childModel.countQ(query)

genDistinctAsChildren = (childQueryFn, childModel) ->
  return distinctAsChildren = (parentModel, field, queryExt) ->
    childQueryFn(parentModel).then (query) ->
      _.extend(query, queryExt)
      childModel.distinctQ(field, query)

genFindChildrenGeneral = (findAsChildrenFns, collection) ->
  return findChildren = (parentModel, query, select, opts) ->
    parentColl = getColl(parentModel)
    fn = findAsChildrenFns[parentColl]
    throw new Error("#{collection} is not a child of #{parentColl}") unless _.isFunction(fn)
    fn(parentModel, query, select, opts)

genFirstQueryFn = ({parentId}) ->
  return firstQueryFn = (parentModel) ->
    query = {}
    query[parentId] = parentModel.get('_id')
    Promise.resolve(query)

genNextQueryFn = ({parentId, model}) ->
  return nextQueryFn = (priorQueryPromise) ->
    Promise.resolve(priorQueryPromise).then (priorQuery) ->
      model.distinctQ('_id', priorQuery).then (vals) ->
        query = {}
        query[parentId] = {"$in": vals}
        query

accumQuery = (query, queryFn) -> queryFn(query)

genChildQueryFn = (firstQueryFn, otherQueryFns) ->
  return (parentModel) ->
    return otherQueryFns.reduce(accumQuery, firstQueryFn(parentModel))

genAllFindFns = (collection, modelCfg) ->
  modelCfg.findAsChildrenFns = {}
  modelCfg.findPriorParentFns = {}
  modelCfg.countAsChildrenFns = {}
  modelCfg.distinctAsChildrenFns = {}

  for parentColl of modelCfg.parentChains
    [firstLink, otherLinks...] = relations[parentColl].fullChildChains[collection]
    firstQueryFn = genFirstQueryFn(firstLink)
    otherQueryFns = otherLinks.map(genNextQueryFn)
    childQueryFn = genChildQueryFn(firstQueryFn, otherQueryFns)
    modelCfg.findAsChildrenFns[parentColl] = genFindAsChildren(childQueryFn, modelCfg.model)
    modelCfg.countAsChildrenFns[parentColl] = genCountAsChildren(childQueryFn, modelCfg.model)
    modelCfg.distinctAsChildrenFns[parentColl] = genDistinctAsChildren(childQueryFn, modelCfg.model)

  modelCfg.findAsChildren = genFindChildrenGeneral(modelCfg.findAsChildrenFns, collection)
  modelCfg.findParent = genFindParent(collection)

# Generates an ascendParentChain function, which calls itself recursively to traverse a chain
# of parents
genAscendParentChain = (collection) ->
  ascendParentChain = (refColl, refModel, chain) ->
    # Get the parent collection from the front of the chain. Define the new chain as the rest
    # of the initial chain.
    [parentColl, chain...] = chain

    id = refModel.get(relations[refColl].parentIds[parentColl])

    # Find the single instance of the parent model by id
    relations[parentColl].model.findCache(id).then (resultParentModel) ->
      # Resolve with the results if the results are empty or the end of the chain is reached
      return resultParentModel if (_.isEmpty(resultParentModel) or !chain.length)
      # Otherwise continue to ascend the chain by looking up ancestors of the parent model
      return ascendParentChain(parentColl, resultParentModel, chain)

genFindParent = (collection) ->
  return findParent = (childModel) ->
    # Alias the child model's collection
    childColl = getColl(childModel)
    # Determine the chain leading from the child model to the desired collection
    parentChain = relations[childColl].parentChains[collection]
    # Return a promise that will resolve when the ancestor is found
    # Start to ascend the chain of the child model, leading to the desired collection
    return genAscendParentChain(collection)(childColl, childModel, parentChain)

getFn = (parentModel, prettyPlural, key) ->
  parentColl = getColl(parentModel)
  childColl = prettyPluralMap[prettyPlural]
  throw new Error("#{prettyPlural} is not a known collection") unless childColl
  childCfg = relations[childColl]
  fn = childCfg[key][parentColl]
  throw new Error("#{parentColl} is not a parent of #{childColl}") unless _.isFunction(fn)
  return fn

count = (parentModel, prettyPlural, query) ->
  countFn = getFn(parentModel, prettyPlural, 'countAsChildrenFns')
  return countFn(parentModel, query)

distinct = (parentModel, prettyPlural, field, query) ->
  distinctFn = getFn(parentModel, prettyPlural, 'distinctAsChildrenFns')
  return distinctFn(parentModel, field, query)

addTf = (name, fn) ->
  dbFunctions[name] = fn

relations = require('./configure')

for collection, modelCfg of relations
  {prettyName, prettyPlural} = modelCfg
  prettyPluralMap[prettyPlural] = collection
  genAllFindFns(collection, modelCfg)
  addTf(prettyPlural, modelCfg.findAsChildren)
  addTf(prettyName, modelCfg.findParent)

addTf 'count', count
addTf 'distinct', distinct

module.exports = relations
