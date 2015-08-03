{_, i, Relationship, utils} = require('./dependencies')

{pluralize} = i()

class ModelProto

  constructor: (@name, @cache, @opts={}) ->
    _.extend(@, @Model.prototype)
    @attachNames()
    @attachInitialParents()
    @attachRelationshipConstructors()
    @parentIds = @getParentIds()
    @relationships = {child: {}, parent: {}}
    @findAsChildrenFns = {}
    @findPriorParentFns = {}
    @countAsChildrenFns = {}
    @distinctAsChildrenFns = {}

  # Get how the model appears as a singular and a plural from the options. If
  # not specified, the model appears as a singular in the form given by
  attachNames: ->
    {@appearsAsSingular, @appearsAsPlural} = @opts
    # Get how the model appears as a singular if not otherwise specified.
    @appearsAsSingular ||= @getAppearsAs()
    # Get how the model appears as a plural if not otherwise specified.
    @appearsAsPlural ||= pluralize(@appearsAsSingular)

  attachRelationshipConstructors: ->
    thisProto = @

    class ParentRelationship extends Relationship.Parent
      constructor: (to, links) ->
        super thisProto, to, links


    class ChildRelationship extends Relationship.Child
      constructor: (to, links) ->
        super thisProto, to, links


    ParentRelationship.name = "#{@name}ParentRelationship"
    ChildRelationship.name = "#{@name}ChildRelationship"

    @ParentRelationship = ParentRelationship
    @ChildRelationship = ChildRelationship

  initParents: (protos) ->
    _.keys(@parentIds).forEach (parentName) =>
      parentRelationship = new this.ParentRelationship(protos[parentName])
      @relationships.parent[parentName] = parentRelationship

  # Adds one level of ancestors for a model configuration
  # Returns true if no ancestors were added, false otherwise
  addAncestors: ->
    _.chain(@relationships.parent)
      .every (parentRelationship) ->
        parentRelationship.addAncestorRelationships()
      .value()

  buildAllChildRelationships: ->
    @relationships.parent.forEach (parentRelationship) ->
      parentRelationship.addCorrespondingChildRelationship()

  toModel: ->
    class Model extends this.constructor.Model
    Model.name = "#{@name}Model"
    _.extend(Model.prototype, @)
    @Model = Model

  buildAllFindFns: ->
    _.map @relationships.parent, (parentRelationship, parentName) =>
      [parent, ancestors...] = parentRelationship.links
      firstQueryFn =

        genFirstQueryFn(parent)
      otherQueryFns = ancestors.map(genNextQueryFn)
      childQueryFn = genChildQueryFn(firstQueryFn, otherQueryFns)
      @findAsChildrenFns[parentName] = genFindAsChildren(childQueryFn, @)
      @countAsChildrenFns[parentName] = genCountAsChildren(childQueryFn, @)
      @distinctAsChildrenFns[parentName] = genDistinctAsChildren(childQueryFn, @)

utils.ctorMustImplement(ModelProto, 'Model')

utils.protoMustImplement(
  ModelProto, 'getAppearsAs', 'getParentIds', 'getFields'
)

module.exports = ModelProto
