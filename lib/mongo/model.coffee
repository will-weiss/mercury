{_, Model, utils} = require('../dependencies')

typeMap = require('./typeMap')

class MongoModel extends Model

  Batcher: require('./Batcher')

  constructor: (name, opts) ->
    super name, opts
    @MongooseModel = null

  genFormNextQuery: (parentIdField) ->
    (ids) ->
      query = {}
      query[parentIdField] = {$in: ids}
      query

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
    _.chain(@MongooseModel.schema.paths)
      .map ({instance, path}) ->
        type = typeMap[instance]
        # TODO implement all types
        return unless type
        description = path
        [path, {type, description}]
      .compact()
      .object()
      .value()

  get: (mongooseModel, key) -> mongooseModel.get(key)

  set: (mongooseModel, key, val) -> mongooseModel.set(key, val)

  getId: (mongooseModel) -> mongooseModel._id

  genFirstQuery = (parentIdField) ->
    query = {}
    query[parentIdField] = @getId()
    query

  toObject: (mongooseModel) -> mongooseModel.toObject()



module.exports = MongoModel
