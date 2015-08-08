{_, graphql} = require('../dependencies')

{ GraphQLString, GraphQLBoolean, GraphQLFloat, GraphQLID, GraphQLString
, GraphQLObjectType, GraphQLList } = graphql

typeMap =
  Boolean: GraphQLBoolean
  Number: GraphQLFloat
  String: GraphQLString
  Date: GraphQLString
  ObjectId: GraphQLID


# From a document field, obtain a corresponding GraphQL field. Return undefined
# if the document field has no valid GraphQL type.
getGraphQLField = (schema, docField, name) ->
  type = getGraphQLType(schema, docField, name)
  if type then {type, description: name}

# Create a GraphQLObjectType for a subdocument.
getGraphQLObjectType = (schema, subDoc, name) ->
  fields = _.mapValues subDoc, (field, path) ->
    getGraphQLField(schema, field, "#{name}.#{path}")
  new GraphQLObjectType({name, fields})

# Recursively define a document field as a GraphQL type.
getGraphQLType = (schema, docField, name) ->
  switch
    # The virtual 'id' field is a GraphQLId
    when name is 'id' then GraphQLID
    # If the docField or its 'type' attribute is a function, the corresponding
    # GraphQL type of that path is given by the type map. Note, that Mongoose's
    # Mixed type does not map to any type.
    when [docField, docField?.type].some(_.isFunction)
      typeMap[schema.paths[name].instance]
    # If the document field is an array, it is interpreted as a list of the type
    # given by the first element of the array.
    # i.e., [String] -> new GraphQLList(GraphQLString)
    when _.isArray(docField)
      new GraphQLList(getGraphQLType(schema, docField[0], name))
    # If the document field is an object, a corresponding GraphQLObjectType is
    # created.
    when _.isObject(docField)
      getGraphQLObjectType(schema, docField, name)
    else
      throw new Error("Could not interpret schema path #{name} as a " +
        "GraphQL type.")

# Iterate over the schema's tree to determine the GraphQL type of each and
# retrieve the fields of all those with a GraphQL type.
getGraphQLFieldsFromSchema = (schema) ->
  _.chain(schema.tree)
    .map (docField, name) ->
      field = getGraphQLField(schema, docField, name)
      if field then [name, field]
    .compact()
    .object()
    .value()


module.exports = getGraphQLFieldsFromSchema
