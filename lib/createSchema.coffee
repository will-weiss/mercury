{_, graphql} = require('./dependencies')

createSchema = (model) ->
  schemaDef =
    name: "#{model.name}Root"
    fields: {}
  schemaDef.fields[model.appearsAsSingular] =
    type: model.objectType
    args:
      id:
        name: 'id',
        type: new graphql.GraphQLNonNull(graphql.GraphQLString)
    resolve: (root, {id}) -> model.findById(id)

  new graphql.GraphQLSchema({query: new graphql.GraphQLObjectType(schemaDef)})


module.exports = createSchema
