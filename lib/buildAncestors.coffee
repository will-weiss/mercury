{_, ParentRelationship} = require('./dependencies')

buildParents = (models) ->
  _.forEach models, (model) ->
    _.extend(model.parentIds, model.getParentIds())
    _.keys(model.parentIds).forEach (parentName) ->
      Parent = models[parentName]
      return unless Parent
      parentRelationship = new ParentRelationship(model, Parent)
      model.relationships.parent[parentName] = parentRelationship

addAncestorsForModel = (model) ->
  _.chain(model.relationships.parent)
    .every (parentRelationship) -> parentRelationship.addAncestorRelationships()
    .value()

addAncestors = (models) ->
  _.chain(models).map(addAncestorsForModel).every().value()

buildAncestors = (models) ->
  buildParents(models)
  allAncestorsBuilt = false
  until allAncestorsBuilt
    allAncestorsBuilt = addAncestors(models)


module.exports = buildAncestors
