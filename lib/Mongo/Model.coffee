{_, Model, Promise} = require('../dependencies')


class MongoModel extends Model
  init: require('./init')

  constructor: (driver, name, definition, opts) ->
    super driver, name, opts
    @MongooseModel = driver.connection.model(name, @toSchema(definition), opts)

  toSchema: (definition) ->
    {mongoose} = @driver
    schemaDef = {}

    set = (path, field) ->
      _.set(schemaDef, path.join('.'), field)

    iter = (val, path) ->
      if _.isFunction(val)
        set(path, val)
      else if _.isString(val)
        set(path, {type: mongoose.SchemaTypes.ObjectId, index: true, ref: val})
      else
        iter(v, path.concat(k)) for k, v of val

    iter(val, [key]) for key, val of definition
    mongoose.Schema(schemaDef)

  createInstance: (doc) ->
    (new this.MongooseModel(doc)).saveAsync().then(_.first)

  updateInstance: (id, updates) ->
    @MongooseModel.findByIdAndUpdateAsync(id, updates).then (result) ->
      _.extend(result, updates)

  removeInstance: (id) ->
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

  getId: (mongooseModel) -> mongooseModel.get('_id')

  set: (mongooseModel, key, val) -> mongooseModel.set(key, val)

  findByIds: (ids, onData) ->
    new Promise (resolve, reject) =>
      stream = @MongooseModel.find({_id: {$in: ids}}).stream()
      stream.on('error', reject)
      stream.on('close', resolve)
      stream.on('data', onData)


module.exports = MongoModel

