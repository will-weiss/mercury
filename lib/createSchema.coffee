{_, graphql} = require('./dependencies')

querySchemaFromModel = (model) ->

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


createMutationSchemaFromModel = (model) ->

  mutationSchemaDef =
    name: _.camelCase("create #{model.name}")
    fields: {}
    resolve: (root, {id}) -> model.findById(id)
    args:
      id:
        name: 'id',
        type: new graphql.GraphQLNonNull(graphql.GraphQLString)

  _.forEach model.fields, (field, name) ->



  new graphql.GraphQLSchema
    mutation: new graphql.GraphQLObjectType(mutationSchemaDef)


module.exports = querySchemaFromModel
