{_} = require('./dependencies')


class Relationship


class SiblingRelationship extends Relationship
  type: 'sibling'

  constructor: (@from, @to, @refKey) ->
    @from.relationships.sibling[@to.name] = @


class ParentChildRelationship extends Relationship
  constructor: (@child, @parent, @links) ->


class ChildRelationship extends ParentChildRelationship
  type: 'child'

  constructor: (child, parent, links) ->
    super child, parent, links
    [@firstLinks..., @lastLink] = @links
    parent.relationships.child[child.name] = @
    parent.fields[child.appearsAsPlural] =
      resolve: @getList.bind(@)
      description: child.name
      type: child.listType

  descend: (links, ids) ->
    [link, next...] = links
    {child, refKey} = link
    query = child.formQuery(refKey, ids)
    promisedIds = child.distinctIds(query)
    return promisedIds unless next.length
    promisedIds.then(@descend.bind(@, next))

  getPriorParentIds: (parentInstance) ->
    ids = [@parent.getId(parentInstance)]
    @descend(@firstLinks, ids)

  getList: (parentInstance) ->
    @getPriorParentIds(parentInstance).then (ids) =>
      query = @child.formQuery(@lastLink.refKey, ids)
      @child.find(query)


class ParentRelationship extends ParentChildRelationship
  type: 'parent'

  constructor: (child, parent, links) ->
    super child, parent, links
    new ChildRelationship(child, parent, links.slice(0).reverse())
    @get = @ascend.bind(@, links)
    child.relationships.parent[parent.name] = @
    child.fields[parent.appearsAsSingular] =
      resolve: @get
      description: parent.name
      type: parent.objectType

  ascend: (links, childInstance) ->
    [link, next...] = links
    {child, parent, refKey} = link
    id = child.get(childInstance, refKey)
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


class ParentChildLink
  constructor: (@child, @parent, @refKey) ->
    new ParentRelationship(@child, @parent, [@])


module.exports =
  ParentChild: ParentChildLink
  Sibling: SiblingRelationship
