{_} = require('./dependencies')


addAncestorsForModel = (model) ->
  _.every model.relationships.parent, (parentRelationship) ->
    parentRelationship.addAncestorRelationships()

addAncestors = (models) ->
  _.chain(models).map(addAncestorsForModel).every().value()

buildModels = (models) ->
  model.init() for model in _.values(models)
  allAncestorsBuilt = false
  until allAncestorsBuilt
    allAncestorsBuilt = addAncestors(models)


module.exports = buildModels
