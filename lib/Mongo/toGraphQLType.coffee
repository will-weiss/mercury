{_, Model, utils, graphql} = require('../dependencies')

typeMap = require('./typeMap')


getGraphQLType = (schema, field, name) ->
  if _.isFunction(field)
    {instance} = schema.paths[name]
    typeMap[instance]
  else if _.isArray(field)
    new graphql.GraphQLList(getGraphQLType(schema, field[0], name))
  else
    fields = _.mapValues field, (subField, path) ->
      getGraphQLType(schema, subField, "#{name}.path")
    new graphql.GraphQLObjectType(name, fields)

getGraphQLFields = (schema) ->
  _.chain(schema.tree)
    .map (field, name) ->
      graphQLType = getGraphQLType(schema, field, name)
      return unless graphQLType
      [name, graphQLType]
    .compact()
    .object()
    .value()


class MongoModel extends Model
  Batcher: require('./Batcher')

  constructor: (app, name, opts) ->
    super app, name, opts
    @MongooseModel = null

  create: (doc) ->
    (new this.MongooseModel(doc)).saveAsync()

  find: (query) ->
    @MongooseModel.findAsync(query)

  count: (query) ->
    @MongooseModel.countAsync(query)

  distinct: (field, query) ->
    @MongooseModel.distinctAsync(field, query)

  distinctIds: (query) ->
    @MongooseModel.distinctAsync('_id', query)

  getAppearsAs: -> @MongooseModel.collection.name

  getParentIdFields: ->
    _.chain(@MongooseModel.schema.tree)
      .map (field, path) -> if field.ref then [field.ref, path]
      .compact()
      .object()
      .value()

  getFields: ->
    getGraphQLFields(@MongooseModel.schema)

  formQuery: (parentIdField, ids) ->
    query = {}
    query[parentIdField] = {$in: ids}
    query

  get: (mongooseModel, key) -> mongooseModel.get(key)

  set: (mongooseModel, key, val) -> mongooseModel.set(key, val)

  getId: (mongooseModel) -> mongooseModel._id


module.exports = MongoModel
