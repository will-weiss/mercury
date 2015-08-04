{_} = require('./dependencies')

class Link
  constructor: (@child, @parent) ->
    @parentId = @child.parentIds[@parent.name]

class ParentRelationship
  constructor: (@child, @parent, links) ->
    @links = links || [new Link(@child, @parent)]

  addAncestorRelationships: ->
    childParents = @child.relationships.parent
    _.chain(@parent.relationships.parent)
      .map (parentAncestorRelationship, ancestorName) =>
        {parent} = parentAncestorRelationship
        links = @links.concat(parentAncestorRelationship.links)
        return if links.length >= childParents[ancestorName]?.links?.length
        ancestorRelationship = new ParentRelationship(@child, parent, links)
        [ancestorName, ancestorRelationship]
      .compact()
      .object()
      .thru (newAncestorRelationships) =>
        _.extend(childParents, newAncestorRelationships)
        _.isEmpty(newAncestorRelationships)
      .value()

module.exports = ParentRelationship
