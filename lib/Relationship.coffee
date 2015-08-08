{_} = require('./dependencies')

class Link
  constructor: (@child, @parent) ->
    @parentIdField = @child.parentIdFields[@parent.name]

class Relationship
  constructor: (@child, @parent, links) ->
    @links = links || [new Link(@child, @parent)]


class ChildRelationship extends Relationship
  type: 'child'

  constructor: (parentRelationship) ->
    {child, parent, links} = parentRelationship
    links = links.slice(0).reverse()
    super child, parent, links
    [@firstLinks..., @lastLink] = @links

  descend: (links, ids) ->
    [link, next...] = links
    {child, parentIdField} = link
    query = {}
    query[parentIdField] = {$in: ids}
    promisedIds = child.distinctIds(query)
    return promisedIds unless next.length
    promisedIds.then(@descend.bind(@, next))

  getPriorParentIds: (parentInstance) ->
    ids = [@parent.getId(parentInstance)]
    @descend(@firstLinks, ids)

  getList: (parentInstance) ->
    @getPriorParentIds(parentInstance).then (ids) =>
      query = {}
      query[@lastLink.parentIdField] = {$in: ids}
      @child.find(query)


class ParentRelationship extends Relationship
  type: 'parent'

  constructor: (child, parent, links) ->
    super child, parent, links
    @parent.relationships.child[@child.name] = new ChildRelationship(@)
    @get = @ascend.bind(@, links)
    # [@firstLink, @lastLinks...] = @links

  ascend: (links, childInstance) ->
    [link, next...] = links
    {parent, parentIdField} = link
    id = childInstance.get(parentIdField)
    promisedParent = parent.findById(id)
    return promisedParent unless next.length
    promisedParent.then(@ascend.bind(@, next))

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

module.exports =
  Parent: ParentRelationship
  Child: ChildRelationship
