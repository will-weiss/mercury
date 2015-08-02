{_, i, Relationship} = require('./dependencies')

{pluralize} = i()

class Model

  constructor: (@models, @name, @cache, @opts={}) ->
    @attachBatcher()
    @attachNames()
    @attachRelationshipConstructors()
    @attachInitialRelationships()

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

  attachInitialRelationships: ->
    @parentIds = @getParentIds()
    @relationships = {child: {}}
    @relationships.parent = _.mapValues @parentIds, (parentId, parentName) =>
      new this.ParentRelationship(@models[parentName])

  # Adds one level of ancestors for a model configuration
  # Returns true if no ancestors were added, false otherwise
  addAncestors: ->
    return _.chain(@relationships.parent)
      .every (parentRelationship) ->
        parentRelationship.addAncestorRelationships()
      .value()

  buildAllChildRelationships: ->
    @relationships.parent.forEach (parentRelationship) ->
      parentRelationship.addCorrespondingChildRelationship()

  findById: (id) ->
    cacheHit = @cache.get(id)
    return cacheHit if cacheHit isnt undefined
    fetch = batcher.by(id)
    cache.set(id, fetch)
    return fetch


module.exports = Model
