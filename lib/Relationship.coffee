{_, graphql} = require('./dependencies')

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
    @parent.fields[@child.appearsAsPlural] =
      resolve: @getList.bind(@)
      description: @child.name
      type: new graphql.GraphQLList(@child.objectType)

  descend: (links, ids) ->
    [link, next...] = links
    {child, parentIdField} = link
    query = child.formQuery(parentIdField, ids)
    promisedIds = child.distinctIds(query)
    return promisedIds unless next.length
    promisedIds.then(@descend.bind(@, next))

  getPriorParentIds: (parentInstance) ->
    ids = [@parent.getId(parentInstance)]
    @descend(@firstLinks, ids)

  getList: (parentInstance) ->
    @getPriorParentIds(parentInstance).then (ids) =>
      query = @child.formQuery(@lastLink.parentIdField, ids)
      @child.find(query)


class ParentRelationship extends Relationship
  type: 'parent'

  constructor: (child, parent, links) ->
    super child, parent, links
    @parent.relationships.child[@child.name] = new ChildRelationship(@)
    @get = @ascend.bind(@, links)
    @child.fields[@parent.appearsAsSingular] =
      resolve: @get
      description: @parent.name
      type: @parent.objectType

  ascend: (links, childInstance) ->
    [link, next...] = links
    {child, parent, parentIdField} = link
    id = child.get(childInstance, parentIdField)
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
