{_, graphql} = require('../dependencies')

typeMap =
  String: graphql.GraphQLString
  Boolean: graphql.GraphQLBoolean
  Number: graphql.GraphQLFloat
  ObjectId: graphql.GraphQLID
  Date: graphql.GraphQLString

getGraphQLField = (schema, docField, name) ->
  type = getGraphQLType(schema, docField, name)
  if type then {type, description: name}

getGraphQLType = (schema, docField, name) ->
  return if name is 'id'
  if _.isFunction(docField) or _.isFunction(docField.type)
    {instance} = schema.paths[name]
    typeMap[instance]
  else if _.isArray(docField)
    new graphql.GraphQLList(getGraphQLType(schema, docField[0], name))
  else
      fields = _.mapValues docField, (docSubField, path) ->
        getGraphQLField(schema, docSubField, "#{name}.#{path}")
      new graphql.GraphQLObjectType({name, fields})

getGraphQLFieldsFromSchema = (schema) ->
  _.chain(schema.tree)
    .map (docField, name) ->
      field = getGraphQLField(schema, docField, name)
      return unless field
      [name, field]
    .compact()
    .object()
    .value()


module.exports = getGraphQLFieldsFromSchema
