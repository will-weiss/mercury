{_, i, Relationship} = require('./dependencies')

{pluralize} = i()

attachNames = (models) ->
  _.forEach models, (Model) ->
    _.extend(Model, _.pick(Model.opts, 'appearsAsSingular', 'appearsAsPlural'))
    # Get how the model appears as a singular if not otherwise specified.
    Model.appearsAsSingular ||= Model.getAppearsAs()
    # Get how the model appears as a plural if not otherwise specified.
    Model.appearsAsPlural ||= pluralize(Model.appearsAsSingular)

buildParents = (models) ->
  _.forEach models, (Model) ->
    _.extend(Model.parentIds, Model.getParentIds())
    _.keys(Model.parentIds).forEach (parentName) ->
      Parent = models[parentName]
      return unless Parent
      parentRelationship = new Relationship.Parent(Model, Parent)
      Model.relationships.parent[parentName] = parentRelationship

addAncestorsForModel = (Model) ->
  _.chain(Model.relationships.parent)
    .every (parentRelationship) -> parentRelationship.addAncestorRelationships()
    .value()

addAncestors = (models) ->
  _.chain(models).map(addAncestorsForModel).every().value()

buildAncestors = (models) ->
  allRelationshipsBuilt = false
  until allRelationshipsBuilt
    allRelationshipsBuilt = addAncestors(models)

buildChildren = (models) ->
  _.forEach models, (Model) ->
    _.forEach Model.relationships.parent, (parentRelationship) ->
      parentRelationship.addCorrespondingChildRelationship()

buildFindFns = (models) ->
  _.forEach models, (Model) ->
    _.forEach Model.relationships.parent, (parentRelationship, parentName) ->
      parentId = Model.parentIds[parentName]
      [firstLink, otherLinks...] = parentRelationship.links
      firstQueryFn = Model.genFirstQueryFn(firstLink)
      otherQueryFns = otherLinks.map (Ancestor) ->
        ancestorId = Model.parentIds[Ancestor.registeredAs]
        Model.genNextQueryFn(ancestorId)

      childQueryFn = genChildQueryFn(firstQueryFn, otherQueryFns)
      modelCfg.findAsChildrenFns[parentColl] = genFindAsChildren(childQueryFn, modelCfg.model)
      modelCfg.countAsChildrenFns[parentColl] = genCountAsChildren(childQueryFn, modelCfg.model)
      modelCfg.distinctAsChildrenFns[parentColl] = genDistinctAsChildren(childQueryFn, modelCfg.model)

  return nextQueryFn = (priorQueryPromise) ->
    Promise.resolve(priorQueryPromise).then (priorQuery) ->
      model.distinctQ('_id', priorQuery).then (vals) ->
        query = {}
        query[parentId] = {"$in": vals}
        query


buildModels = (models) ->
  attachNames(models)
  buildParents(models)
  buildAncestors(models)
  buildChildren(models)

module.exports = buildModels
