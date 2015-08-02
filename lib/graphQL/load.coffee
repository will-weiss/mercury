{_, graphql, allong, models} = DEPENDENCIES
{ GraphQLObjectType, GraphQLNonNull, GraphQLSchema, GraphQLString,
  GraphQLBoolean, GraphQLFloat, GraphQLList } = graphql

GRAPH_QL_OBJECT_TYPES = require('./objectTypes')
getProjection = require('./getProjection')

load = (schemas) ->
  schemas.broker = new GraphQLSchema
    query: new GraphQLObjectType
      name: 'BrokerRoot'
      fields:
        broker:
          type: GRAPH_QL_OBJECT_TYPES.Broker
          args:
            _id:
              name: '_id',
              type: new GraphQLNonNull(GraphQLString)
          resolve: (root, {_id}, req, fieldASTs) =>
            req.agent.masqueradeAnalyst(_id).then =>
              projections = getProjection(fieldASTs)
              models.Broker.findByIdQ(_id, projections)

  schemas.employer = new GraphQLSchema
    query: new GraphQLObjectType
      name: 'EmployerRoot'
      fields:
        employer:
          type: GRAPH_QL_OBJECT_TYPES.Employer
          args:
            _id:
              name: '_id',
              type: new GraphQLNonNull(GraphQLString)
          resolve: (root, {_id}, req, fieldASTs) =>
            req.agent.masqueradeAdministrator(_id).then =>
              projections = getProjection(fieldASTs)
              models.Employer.findByIdQ(_id, projections)

module.exports = load
