{graphql} = require('../dependencies')

module.exports =
  String: graphql.GraphQLString
  Object: graphql.GraphQLObjectType
  Mixed: graphql.GraphQLObjectType
  Boolean: graphql.GraphQLBoolean
  Number: graphql.GraphQLFloat
  ObjectId: graphql.GraphQLString
  Date: graphql.GraphQLString
