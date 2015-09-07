{graphql: {GraphQLList, GraphQLNonNull}} = require('./dependencies')

exports.mustImplement = (Ctor, fnNames...) ->
  fnNames.forEach (fnName) ->
    Ctor[fnName] = ->
      throw new Error("#{Ctor.name}.prototype must implement #{fnName}.")

# Create functions for constructing GraphQL types from other types. WeakMaps are
# used so that already created compound types may be reused.

# GraphQLList
toList = new WeakMap()
exports.getListType = (graphQLType) ->
  unless toList.has(graphQLType)
    toList.set(graphQLType, new GraphQLList(graphQLType))
  toList.get(graphQLType)

# GraphQLNonNull
toNonNull = new WeakMap()
exports.getNonNullType = (graphQLType) ->
  unless toNonNull.has(graphQLType)
    toNonNull.set(graphQLType, new GraphQLNonNull(graphQLType))
  toNonNull.get(graphQLType)
