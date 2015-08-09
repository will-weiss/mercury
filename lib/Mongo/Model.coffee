{_, Model} = require('../dependencies')


class MongoModel extends Model
  Batcher: require('./Batcher')
  init: require('./init')

  constructor: (app, name, opts) ->
    super app, name, opts
    @MongooseModel = null

  create: (doc) ->
    creationPromise = (new this.MongooseModel(doc)).saveAsync().then(_.first)
    creationPromise.then (created) => @cache.set(@getId(created), created)
    creationPromise

  update: (id, updates) ->
    updatePromise = @MongooseModel
      .findByIdAndUpdateAsync(id, updates)
      .then (result) -> _.extend(result, updates)
    @cache.set(id, updatePromise)
    updatePromise

  remove: (id) ->
    @cache.set(id, null)
    this.MongooseModel.findByIdAndRemove(id)

  find: (query) ->
    @MongooseModel.findAsync(query)

  count: (query) ->
    @MongooseModel.countAsync(query)

  distinct: (field, query) ->
    @MongooseModel.distinctAsync(field, query)

  distinctIds: (query) ->
    @MongooseModel.distinctAsync('_id', query)

  formQuery: (parentIdField, ids) ->
    query = {}
    query[parentIdField] = {$in: ids}
    query

  get: (mongooseModel, key) -> mongooseModel.get(key)

  set: (mongooseModel, key, val) -> mongooseModel.set(key, val)

  getId: (mongooseModel) -> mongooseModel._id


module.exports = MongoModel

