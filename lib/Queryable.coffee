{graphql} = require('./dependencies')

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

  addField: (name, type) ->
    return unless type
    @fields[name] = {type, description: "#{name} of #{@name}"}

module.exports = Queryable
