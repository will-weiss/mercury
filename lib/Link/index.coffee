{_} = require('./dependencies')

ParentRelationship = require('./ParentRelationship')

class SiblingRelationship
  type: 'sibling'

  constructor: (@from, @to, @refKey) ->
    @from.relationships.sibling[@to.name] = @


class ParentChildLink
  constructor: (@child, @parent, @refKey) ->
    new ParentRelationship(@child, @parent, [@])


module.exports =
  ParentChild: ParentChildLink
  Sibling: SiblingRelationship
