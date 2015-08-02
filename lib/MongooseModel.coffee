{Batcher, Model, utils} = require('./dependencies')

getList = (ids) ->
  utils.toFlood(@model.find({_id: {$in: ids}}).stream()).forEach (result) =>
    deferred = @deferreds[result._id]
    delete @deferreds[result._id]
    deferred.resolve(result)

class MongoooseModelBatcher extends Batcher

  constructor: (wait) ->
    super getList, wait


class MongooseModel extends Model
  constructor: (models, name, cache, @model, opts) ->
    super models, name, cache, opts

  Batcher: MongoooseModelBatcher

  getParentIds: ->
    _.chain(@model.schema.tree)
      .pairs()
      .map ([path, field]) -> if field.ref then [field.ref, path]
      .compact()
      .object()
      .value()

  getAppearsAs: -> @model.collection.name


module.exports = MongooseModel
