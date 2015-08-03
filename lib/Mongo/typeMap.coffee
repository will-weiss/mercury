{graphql} = require('../dependencies')

module.exports =
  String: graphql.GraphQLString
  Mixed: graphql.GraphQLObjectType
  Boolean: graphql.GraphQLBoolean
  Number: graphql.GraphQLFloat
  ObjectId: graphql.GraphQLString
  Date: graphql.GraphQLString
