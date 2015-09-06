{_, graphql, Link} = require('./dependencies')

{ GraphQLString, GraphQLBoolean, GraphQLFloat, GraphQLID, GraphQLString
, GraphQLObjectType, GraphQLList } = graphql

# Maintain a type representing a list of ids.
idListType = new GraphQLList(GraphQLID)

# A queryable entity corresponding with a persistent resource.
class Queryable
  constructor: (@name) ->
    @inputName = "#{@name}Input"
    @fields = {}
    @inputFields = {}

    # Construct the object type for this queryable entity.
    @objectType = new graphql.GraphQLObjectType
      name: @name
      description: @name
      fields: @fields

    # Construct the input object type for this queryable entity.
    @inputObjectType = new graphql.GraphQLInputObjectType
      name: @inputName
      description: @inputName
      fields: @inputFields

    @listType = new graphql.GraphQLList(@objectType)
    @inputListType = new graphql.GraphQLList(@inputObjectType)

  addField: (name, type) ->
    return unless type
    @fields[name] = {type, description: "#{name} of #{@name}"}

  addInputField: (name, type) ->
    return unless type
    @inputFields[name] = {type, description: "input #{name} of #{@name}"}


module.exports = Queryable
