{_, Model, utils} = require('../dependencies')

getGraphQLFieldsFromSchema = require('./getGraphQLFieldsFromSchema')


class MongoModel extends Model
  Batcher: require('./Batcher')

  constructor: (app, name, opts) ->
    super app, name, opts
    @MongooseModel = null

  create: (doc) ->
    (new this.MongooseModel(doc)).saveAsync().then(_.first)

  find: (query) ->
    @MongooseModel.findAsync(query)

  count: (query) ->
    @MongooseModel.countAsync(query)

  distinct: (field, query) ->
    @MongooseModel.distinctAsync(field, query)

  distinctIds: (query) ->
    @MongooseModel.distinctAsync('_id', query)

  getAppearsAs: -> _.camelCase(@name)

  getParentIdFields: ->
    _.chain(@MongooseModel.schema.tree)
      .map (field, path) -> if field.ref then [field.ref, path]
      .compact()
      .object()
      .value()

  getFields: ->
    getGraphQLFieldsFromSchema(@MongooseModel.schema)

  formQuery: (parentIdField, ids) ->
    query = {}
    query[parentIdField] = {$in: ids}
    query

  get: (mongooseModel, key) -> mongooseModel.get(key)

  set: (mongooseModel, key, val) -> mongooseModel.set(key, val)

  getId: (mongooseModel) -> mongooseModel._id


module.exports = MongoModel
