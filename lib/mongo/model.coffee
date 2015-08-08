{_, Model, utils} = require('../dependencies')

typeMap = require('./typeMap')

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
    _.chain(@MongooseModel.schema.tree)
      .map ({instance, path}) ->
        type = typeMap[instance]
        # TODO implement all types
        return unless type
        description = path
        [path, {type, description}]
      .compact()
      .object()
      .value()

  formQuery: (parentIdField, ids) ->
    query = {}
    query[parentIdField] = {$in: ids}
    query

  get: (mongooseModel, key) -> mongooseModel.get(key)

  set: (mongooseModel, key, val) -> mongooseModel.set(key, val)

  getId: (mongooseModel) -> mongooseModel._id


module.exports = MongoModel
