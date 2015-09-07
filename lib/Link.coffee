{_} = require('./dependencies')


# Link a parent and child. Maintain the key by which instances of the child
# refer to the id of their corresponding parent instance.
class ParentChildLink
  constructor: (@child, @parent, @refKey) ->
    new ParentChildRelationship(@child, @parent, [@])


# An association between a child and parent model. The links of a parent-child
# relationship are traversed forwards to find parents and backwards to find
# children. Fields are added to the child and parent such that each may be
# queried from one another.
class ParentChildRelationship
  constructor: (@child, @parent, @links) ->
    {child, parent, links} = @

    # Set this relationship on both the parent and child.
    parent.relationships.child[child.name] = @
    child.relationships.parent[parent.name] = @

    # Maintain a reversed copy of the links to find children from instances of a
    # parent. All links but the final link lead to the prior parent and the last
    # link is the parent link.
    [@linksToPriorParent..., @childLink] = links.slice(0).reverse()

    # Find a parent by ascending all links leading from the child to the parent.
    @findParent = @ascend.bind(@, links)

    # Add a field to the child corresponding to the parent which resolves by
    # finding the parent of a supplied instance of a child.
    childToParent = child.addField(parent.appearsAsSingular, parent.objectType)
    childToParent.resolve = @findParent

    # Add a field to the parent corresponding to the child which resolves by
    # finding the children of a supplied instance of a parent.
    parentToChildren = parent.addField(child.appearsAsPlural, child.listType)
    parentToChildren.resolve = @findChildren.bind(@)

  # Find children from an instance of a parent by getting the ids of prior
  # parent instances, then querying to find the child instances with a
  # referrant key in those ids.
  findChildren: (parentInstance) ->
    @getPriorParentIds(parentInstance).then (ids) =>
      query = @child.formQuery(@childLink.refKey, ids)
      @child.find(query)

  # Get the ids of prior parents by descending the links to the prior parent.
  # Initially, the ids are an array with a single element, the id of the
  # supplied parent instance.
  getPriorParentIds: (parentInstance) ->
    ids = [@parent.getId(parentInstance)]
    Promise.resolve().then(@descend.bind(@, @linksToPriorParent, ids))

  # Descend links to find ids of descendants given the ids of the immediate
  # parents of those descendants.
  descend: (links, ids) ->
    return ids unless links.length and ids.length
    [link, next...] = links
    {child, refKey} = link
    query = child.formQuery(refKey, ids)
    child.distinctIds(query).then(@descend.bind(@, next))

  # Ascend links to find an ancestor given an immediate child of that ancestor.
  ascend: (links, childInstance) ->
    return childInstance unless links.length and childInstance
    [link, next...] = links
    {child, parent, refKey} = link
    id = child.get(childInstance, refKey)
    parent.findById(id).then(@ascend.bind(@, next))

  # Iterate over the parent relationships of the parent to find new/shorter
  # ancestor relationships. Return true if at least one ancestor relationship
  # was added in this way.
  addAncestors: ->
    _.chain(@parent.relationships.parent)
      .map(@conditionallyAddAncestor.bind(@)).some().value()

  # Conditionally add a new parent-child relationship between a child and an
  # ancestor. A relationship should be added if the child does not already have
  # a defined relationship with the ancestor or if the proposed relationship has
  # fewer links than the existing relationship.
  conditionallyAddAncestor: (parentAncestorRelationship, ancestorName) ->
    {links, parent} = parentAncestorRelationship
    links = @links.concat(links)
    existingLen = @child.relationships.parent[ancestorName]?.links?.length
    return if links.length >= existingLen
    new ParentChildRelationship(@child, parent, links)

# Link a model with its sibling. A sibling relationship consists of a single
# link, so this functions as a sibling relationship. A field is added which
# resolves with the sibling instances of a supplied model.
class SiblingLink
  constructor: (@from, @to, @refKey) ->
    @from.relationships.sibling[@to.name] = @
    toSibling = @from.fields(@to.appearsAsPlural, @to.listType)
    toSibling.resolve = @findSiblings.bind(@)

  # Find siblings by getting their ids from the supplied instance and finding
  # each by id.
  findSiblings: (fromInstance) ->
    ids = @from.get(fromInstance, @refKey)
    Promise.all(@to.findById(id) for id in ids)


module.exports =
  ParentChild: ParentChildLink
  Sibling: SiblingLink
