{ModelProto} = require('../dependencies')

typeMap = require('./typeMap')

class MongoModelProto extends ModelProto
  constructor: (models, name, cache, @MongooseModel, opts) ->
    super models, name, cache, opts

  getAppearsAs: -> @MongooseModel.collection

  getParentIds: ->
    _.chain(@MongooseModel.schema.tree)
      .map (field, path) -> if field.ref then [field.ref, path]
      .compact()
      .object()
      .value()

  getFields: ->
    _.chain(@MongooseModel.schema.paths)
      .map ({instance, path}) ->
        return unless instance of typeMap
        type = typeMap[instance]
        description = path
        [path, {type, description}]
      .compact()
      .object()
      .value()

  toModel: ->
    class Batcher extends this.constructor.Model.Batcher
    Batcher.MongooseModel = @MongooseModel
    Model = super
    Model.Batcher = Batcher
    Model


MongoModelProto.Model = require('./Model')

module.exports = MongoModelProto
