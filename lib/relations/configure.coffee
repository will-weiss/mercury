{_} = require('../dependencies')

getColl = (m) -> m.collection.name

# Loads the parentIds of a model configuration, indicating which fields on the model map to which
# fields on the parent.
loadParentInfos = (modelCfg) ->
  modelCfg.parentIds = {}
  for parentColl, parentId of (modelCfg.parents || {})
    modelCfg.parentIds[parentColl] = parentId

addInitialConfigInfo = ([collection, modelCfg]) ->
  # The pretty name of the model is the collection if not otherwise supplied
  modelCfg.prettyName ||= collection
  # The pretty plural name of the model is the pretty name with an 's' if not otherwise supplied
  modelCfg.prettyPlural ||= (modelCfg.prettyName + 's')
  modelCfg.childChains = {}
  modelCfg.parentChains = {}
  loadParentInfos(modelCfg)
  for parentColl of (modelCfg.parents || {})
    modelCfg.parentChains[parentColl] = [parentColl]

getAncestorChains = (parentChain, parentColl) ->
  _.map relations[parentColl].parentChains, (parentToAncestorChain, ancestor) ->
    {parentChain, parentToAncestorChain, ancestor}

genIsAncestorChainShorter = (modelCfg) ->
  return isAncestorChainShorter = ({parentChain, parentToAncestorChain, ancestor}) ->
    return true unless ancestorChain = modelCfg.parentChains[ancestor]
    return ancestorChain.length > parentChain.length + parentToAncestorChain.length

constructAncestorChain = ({parentChain, parentToAncestorChain, ancestor}) ->
  {ancestor, ancestorChain: parentChain.concat(parentToAncestorChain)}

genAddAncestorChain = (modelCfg) ->
  return addAncestorChain = ({ancestor, ancestorChain}) ->
    modelCfg.parentChains[ancestor] = ancestorChain

# Adds one level of ancestors for a model configuration
# Returns true if no ancestors were added, false otherwise
addAncestors = ([collection, modelCfg]) ->
  return _.chain(modelCfg.parentChains)
    .map(getAncestorChains)
    .flatten()
    .filter(genIsAncestorChainShorter(modelCfg))
    .map(constructAncestorChain)
    .each(genAddAncestorChain(modelCfg))
    .isEmpty()
    .value()

getFullChildChain = (collection, childChain) ->
  parentChain = [collection].concat(_.initial(childChain))
  return _.chain(_.zip(childChain, parentChain))
    .map ([childColl, parentColl]) ->
      parentId = relations[childColl].parentIds[parentColl]
      {model} = relations[parentColl]
      return {model, parentId}
    .value()

addFullChains = ([collection, modelCfg]) ->
  modelCfg.fullChildChains = _.chain(modelCfg.childChains)
    .map (childChain, childColl) ->
      [childColl, getFullChildChain(collection, childChain)]
    .object()
    .value()

buildParentChains = (relationsChain) -> relationsChain.map(addAncestors).every().value()

addChildChains = ([collection, modelCfg]) ->
  return _.chain(modelCfg.parentChains)
    .each (parentChain, parentColl) ->
      childChain = [collection].concat(parentChain)
      childChain.pop()
      childChain.reverse()
      relations[parentColl].childChains[collection] = childChain
    .value()

cfgArr = require('./configArray')

# The titan configuration maps collection names to the configurations of those models
relations = _.object([getColl(modelCfg.model), modelCfg] for modelCfg in cfgArr)
# Keep a configuration for the Maxwell model, which is treated differently

relationsChain = _.chain(relations).pairs()

relationsChain.each(addInitialConfigInfo).value()

chainsExhausted = false

while !chainsExhausted
  chainsExhausted = buildParentChains(relationsChain)

relationsChain.map(addChildChains).value()
relationsChain.map(addFullChains).value()

module.exports = relations
