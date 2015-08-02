{_} = require('../dependencies')

PRETTY_NAMES =
  FamilyProductAvailable: prettyName: 'fpa'
  FamilyProductEnrollment: prettyName: 'fpe'
  EmployerGroup: prettyName: 'group'
  Family: prettyPlural: 'families'

# Get an array of configs for each model
cfgArr = _.map models, (model, nm) ->
  # The config references the model
  cfg = {model}
  # Add the pretty names of the model, if those exist
  cfg[k] = pretty for k, pretty of PRETTY_NAMES[nm] || {}
  # Add the parents of this model by examining its schema
  cfg.parents = _.chain(model.schema.tree)
    .pairs()
    # Get the potentially null parent model refered to by the path
    .map ([path, field]) -> [models[field?.ref], path]
    # Examine only those parents that exist
    .filter ([parent, path]) -> parent
    # Get the collection name of each parent
    .map ([parent, parentId]) -> [parent.collection.name, parentId]
    # Collect an object mapping the parent collection name to the parentId
    .object()
    .value()
  # Return this model's config
  cfg

module.exports = cfgArr
