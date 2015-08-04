{_, Model, utils} = require('../dependencies')

typeMap = require('./typeMap')

class MongoModel extends Model

  constructor: (doc, fields, skipId) ->
    @mongooseModel = new this.constructor.MongooseModel(doc, fields, skipId)

  get: (key) -> @mongooseModel.get(key)

  getId: -> @mongooseModel._id

Model.genFirstQueryFn = (parentId) ->
  ->
    query = {}
    query[parentId] = @getId()
    query

MongoModel.genFormNextQuery = (parentId) ->
  (ids) ->
    query = {}
    query[parentId] = {$in: ids}
    query

MongoModel.find = (query) ->
  @MongooseModel.findAsync(query)

MongoModel.count = (query) ->
  @MongooseModel.countAsync(query)

MongoModel.distinct = (field, query) ->
  @MongooseModel.distinctAsync(field, query)

MongoModel.distinctIds = (query) ->
  @MongooseModel.distinctAsync('_id', query)

MongoModel.getAppearsAs = -> @MongooseModel.collection.name

MongoModel.getParentIds = ->
  _.chain(@MongooseModel.schema.tree)
    .map (field, path) -> if field.ref then [field.ref, path]
    .compact()
    .object()
    .value()

MongoModel.getFields = ->
  _.chain(@MongooseModel.schema.paths)
    .map ({instance, path}) ->
      # TODO
      return unless instance of typeMap
      type = typeMap[instance]
      description = path
      [path, {type, description}]
    .compact()
    .object()
    .value()


MongoModel.Batcher = require('./Batcher')

utils.ctorMustImplement(MongoModel, 'MongooseModel')

module.exports = MongoModel
