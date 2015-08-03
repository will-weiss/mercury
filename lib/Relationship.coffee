{_} = require('./dependencies')

class Relationship
  constructor: (@from, @to, links) ->
    @links = links || [@to]


class ChildRelationship extends Relationship
  type: 'child'


class ParentRelationship extends Relationship
  type: 'parent'

  addAncestorRelationships: ->
    fromParents = @from.relationships.parent
    _.chain(@to.relationships.parent)
      .map (parentAncestorRelationship, ancestorName) =>
        {to} = parentAncestorRelationship
        links = @links.concat(parentAncestorRelationship.links)
        return if links.length >= fromParents[ancestorName]?.links?.length
        ancestorRelationship = new this.from.ParentRelationship(to, links)
        [ancestorName, ancestorRelationship]
      .compact()
      .object()
      .thru (newAncestorRelationships) =>
        _.extend(fromParents, newAncestorRelationships)
        _.isEmpty(newAncestorRelationships)
      .value()

  addCorrespondingChildRelationship: ->
    links = _.chain([@from].concat(@links)).reverse().rest().value()
    childRelationship = new this.to.ChildRelationship(@from, links)
    @to.relationships.child[@from.name] = childRelationship


module.exports =
  Parent: ParentRelationship
  Child: ChildRelationship
