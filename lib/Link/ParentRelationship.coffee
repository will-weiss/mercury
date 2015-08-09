{_} = require('./dependencies')


class Link
  constructor: (@from, @to, @refKey) ->


class SiblingRelationship extends Link




class ParentChildLink extends Link
  constructor: (child, parent, refKey) ->
    super child, parent, refKey
    new ParentChildRelationship(child, parent, [@])


class ParentChildRelationship
  type: 'ParentChild'

  constructor: (@child, @parent, @links) ->
    {child, parent, links} = @
    [@linksToPriorParents..., @parentLink] = links.slice(0).reverse()
    @get = @ascend.bind(@, links)

    parent.relationships.child[child.name] = @
    child.relationships.parent[parent.name] = @

    parent.fields[child.appearsAsPlural] =
      resolve: @getList.bind(@)
      description: child.name
      type: child.listType

    child.fields[parent.appearsAsSingular] =
      resolve: @get
      description: parent.name
      type: parent.objectType

  descend: (links, ids) ->
    [link, next...] = links
    {child, refKey} = link
    query = child.formQuery(refKey, ids)
    promisedIds = child.distinctIds(query)
    return promisedIds unless next.length
    promisedIds.then(@descend.bind(@, next))

  getPriorParentIds: (parentInstance) ->
    ids = [@parent.getId(parentInstance)]
    @descend(@linksToPriorParents, ids)

  getList: (parentInstance) ->
    @getPriorParentIds(parentInstance).then (ids) =>
      query = @child.formQuery(@parentLink.refKey, ids)
      @child.find(query)

  ascend: (links, childInstance) ->
    [link, next...] = links
    {child, parent, refKey} = link
    id = child.get(childInstance, refKey)
    promisedParent = parent.findById(id)
    return promisedParent unless next.length
    promisedParent.then(@ascend.bind(@, next))

  determineAncestry: (childParents, parentAncestorRelationship, ancestorName) ->
    {parent} = parentAncestorRelationship
    links = @links.concat(parentAncestorRelationship.links)
    return if links.length >= childParents[ancestorName]?.links?.length
    ancestorRelationship = new ParentChildRelationship(@child, parent, links)
    [ancestorName, ancestorRelationship]

  extendRelationships: (childParents, newAncestorRelationships) ->
    _.extend(childParents, newAncestorRelationships)
    _.isEmpty(newAncestorRelationships)

  addAncestorRelationships: ->
    childParents = @child.relationships.parent
    _.chain(@parent.relationships.parent)
      .map(@determineAncestry.bind(@, childParents))
      .compact()
      .object()
      .thru(@extendRelationships.bind(@, childParents))
      .value()

module.exports = ParentChildRelationship
