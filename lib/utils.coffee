{graphql: {GraphQLList, GraphQLNonNull}} = require('./dependencies')

# Maintain a map indicating prototype properties that constructors must
# implement given their interface.
interfacesMustImplement = new WeakMap()

# Set the properties required by an interface.
exports.mustImplement = (Interface, mustImplement...) ->
  interfacesMustImplement.set(Interface, mustImplement)

# Checks if the prototype of a constructor has the properties required by the
# constructor's interface. The implementation of required properties are
# recursively check as well.
exports.checkImplementation = (Ctor) ->
  Interface = Ctor?.__super__?.constructor
  mustImplement = interfacesMustImplement.get(Interface)
  return unless mustImplement
  for implement in mustImplement
    implemented = Ctor::[implement]
    if implemented
      exports.checkImplementation(implemented)
    else
      throw new Error("#{Ctor.name} must implement #{implement} as required by
        its interface #{Interface.name}.")


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


exports.snake = (str) ->
  str.replace(/\W/g, '_')
