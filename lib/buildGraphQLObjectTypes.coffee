{_, allong, graphql} = require('./dependencies')

addObjectType = (model, name) ->

  model.fields = model.getFields()

  model.objectType = new graphql.GraphQLObjectType
    name: name
    description: model.appearsAsSingular
    fields: => model.fields

addResolves = (model) ->

  _.forEach model.relationships.child, (childRelationship, childName) ->
    {child, getList} = childRelationship
    model.fields[child.appearsAsPlural] =
      resolve: getList.bind(childRelationship)
      description: childName
      type: new graphql.GraphQLList(child.objectType)

  _.forEach model.relationships.parent, (parentRelationship, parentName) ->
    {parent, get} = parentRelationship
    model.fields[parent.appearsAsSingular] =
      resolve: get.bind(parentRelationship)
      description: parentName
      type: parent.objectType


buildGraphQLObjectTypes = (models) ->
  _.forEach(models, addObjectType)
  _.forEach(models, addResolves)

module.exports = buildGraphQLObjectTypes
