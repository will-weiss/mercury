{_, graphql, graphQLSchemas, Controller} = DEPENDENCIES

class GraphQLServer extends Controller
  route: '/api/graphql'

  constructor: ->
    _.map(graphQLSchemas, @initSchema.bind(@))

  initSchema: (schema, nm) ->
    @addEndpoint 'get', "#{@route}/#{nm}", (req, res) ->
      graphql.graphql(schema, JSON.parse(req.query.query).query, req)
      .then (result) =>
        res.status(200).send(result)
      .catch (err) =>
        console.log(err)
        res.status(500).send(err)

module.exports = GraphQLServer
