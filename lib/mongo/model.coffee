{_, Model, utils} = require('../dependencies')

typeMap = require('./typeMap')

class MongoModel extends Model

  Batcher: require('./Batcher')
  ModelInstance: require('./ModelInstance')

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
        type = typeMap[instance]
        # TODO
        return unless type
        description = path
        [path, {type, description}]
      .compact()
      .object()
      .value()

  createInstance: (doc, fields, skipId) ->
    modelInstance = super
    modelInstance.mongooseModel = new this.MongooseModel(doc, fields, skipId)
    modelInstance


module.exports = MongoModel
