{_} = require('./dependencies')

# Adds ancestors for a model. Returns true if some ancestor was added this way.
addAncestorsForModel = (model) ->
  _.some model.relationships.parent, (parentRelationship) ->
    parentRelationship.addAncestors()

# Adds ancestors for models. Returns true if some ancestor was added this way.
addAncestors = (models) ->
  _.chain(models).map(addAncestorsForModel).some().value()

# Initializes all models and completes building the relationships between them
# by adding ancestors until there are no more to add.
module.exports = (models) ->
  model.init() for model in _.values(models)
  allAncestorsAdded = false
  until allAncestorsAdded
    allAncestorsAdded = not addAncestors(models)
