{_, graphql, utils} = require('./dependencies')

{GraphQLObjectType, GraphQLInputObjectType} = graphql

# A queryable entity corresponding with a persistent resource.
class Queryable
  constructor: (@name) ->
    @fields = {}
    @inputFields = {}
    # Construct the object type for this queryable entity.
    @objectType = new GraphQLObjectType({@name, @fields})
    # Construct the input object type for this queryable entity.
    @inputObjectType = new GraphQLInputObjectType({@name, fields: @inputFields})
    # Create list types for object and input types.
    @listType = utils.getListType(@objectType)
    @inputListType = utils.getListType(@inputObjectType)

  addField: (name, type) ->
    @fields[name] = {type, description: "#{name} of #{@name}"}

  addInputField: (name, type) ->
    @inputFields[name] = {type, description: "input #{name} of #{@name}"}


module.exports = Queryable
