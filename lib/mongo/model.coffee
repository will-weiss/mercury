{_, Model, utils} = require('../dependencies')

typeMap = require('./typeMap')

class MongoModel extends Model

  Batcher: require('./Batcher')

  constructor: (@MongooseModel) ->

  genFirstQueryFn: (parentId) ->
    ->
      query = {}
      query[parentId] = @getId()
      query

  genFormNextQuery: (parentId) ->
    (ids) ->
      query = {}
      query[parentId] = {$in: ids}
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

  getParentIds: ->
    _.chain(@MongooseModel.schema.tree)
      .map (field, path) -> if field.ref then [field.ref, path]
      .compact()
      .object()
      .value()

  getFields: ->
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



module.exports = MongoModel
