{_, Relationship} = require('./dependencies')

buildParents = (models) ->
  _.forEach models, (model) ->
    _.keys(model.parentIdFields).forEach (parentName) ->
      parent = models[parentName]
      # TODO throw here?
      return unless parent
      parentRelationship = new Relationship.Parent(model, parent)
      model.relationships.parent[parentName] = parentRelationship

addAncestorsForModel = (model) ->
  _.every model.relationships.parent, (parentRelationship) ->
    parentRelationship.addAncestorRelationships()

addAncestors = (models) ->
  _.chain(models).map(addAncestorsForModel).every().value()

addMutations = (models) ->


buildModels = (models) ->
  model.init() for model in _.values(models)
  buildParents(models)
  allAncestorsBuilt = false
  until allAncestorsBuilt
    allAncestorsBuilt = addAncestors(models)


module.exports = buildModels
