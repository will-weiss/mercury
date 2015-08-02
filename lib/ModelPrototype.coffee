{_, i, Relationship, Model} = require('./dependencies')

{pluralize} = i()


class ModelPrototype

  constructor: (@protos, @name, @cache, @opts={}) ->
    @attachBatcher()
    @attachNames()
    @attachInitialParents()
    @attachRelationshipConstructors()
    @parentIds = @getParentIds()
    @relationships = {child: {}, parent: {}}

  attachBatcher: ->
    _.defaults(@opts, {wait: 1})
    @batcher = new this.Batcher(@, @opts.wait)

  # Get how the model appears as a singular and a plural from the options. If
  # not specified, the model appears as a singular in the form given by
  attachNames: ->
    {@appearsAsSingular, @appearsAsPlural} = @opts
    # Get how the model appears as a singular if not otherwise specified.
    @appearsAsSingular ||= @getAppearsAs()
    # Get how the model appears as a plural if not otherwise specified.
    @appearsAsPlural ||= pluralize(@appearsAsSingular)

  attachRelationshipConstructors: ->
    thisModel = @

    class ParentRelationship extends Relationship.Parent
      constructor: (to, links) ->
        super thisModel, to, links


    class ChildRelationship extends Relationship.Child
      constructor: (to, links) ->
        super thisModel, to, links


    ParentRelationship.name = "#{@name}ParentRelationship"
    ChildRelationship.name = "#{@name}ChildRelationship"

    @ParentRelationship = ParentRelationship
    @ChildRelationship = ChildRelationship

  initParents: ->
    _.keys(@parentIds).forEach (parentName) =>
      parentRelationship = new this.ParentRelationship(@protos[parentName])
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
    class SpecificModel extends Model
    _.extend(SpecificModel.prototype, @)
    SpecificModel.name = "#{@name}Model"
    SpecificModel


module.exports = ModelPrototype
