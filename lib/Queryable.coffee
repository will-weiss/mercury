{_, utils, graphql} = require('./dependencies')

{GraphQLObjectType, GraphQLInputObjectType} = graphql


# A queryable entity.
class Queryable
  constructor: (@name) ->
    @fields = {}
    @inputFields = {}
    # Construct the object type for this queryable entity.
    @objectType = new GraphQLObjectType({@name, @fields})
    # Construct the input object type for this queryable entity.
    @inputObjectType = new GraphQLInputObjectType({
      name: "input_#{@name}"
      fields: @inputFields
    })
    # Create list types for object and input types.
    @listType = utils.getListType(@objectType)
    @inputListType = utils.getListType(@inputObjectType)

  addField: (name, type) ->
    fieldName = utils.snake(name)
    @fields[fieldName] = {type, description: "#{name} of #{@name}"}

  addInputField: (name, type) ->
    fieldName = utils.snake(name)
    @inputFields[fieldName] = {type, description: "input #{name} of #{@name}"}


module.exports = Queryable
