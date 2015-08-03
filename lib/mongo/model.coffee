{Model} = require('../dependencies')

class MongoModel extends Model

  constructor: (@mongooseModel) ->
    super

  get: (key) -> @mongooseModel.get(key)

  getId: -> @mongooseModel._id


MongoModel.find = (query) ->
  @MongooseModel.findQ(query)

MongoModel.count = (query) ->
  @MongooseModel.countQ(query)

MongoModel.distinct = (field, query) ->
  @MongooseModel.distinctQ(field, query)

MongoModel.distinctIds = (query) ->
  @MongooseModel.distinctQ('_id', query)

MongoModel.formNextQuery = (parentId, ids) ->
  query = {}
  query[parentId] = {$in: ids}
  query


MongoModel.Batcher = require('./Batcher')

module.exports = MongoModel
