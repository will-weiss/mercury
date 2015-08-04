{_, ModelInstance} = require('../dependencies')

class MongoModelInstance extends ModelInstance
  constructor: (@MongoModel, doc, fields, skipId) ->
    {MongooseModel} = @MongoModel
    @mongooseModel = new MongooseModel(doc, fields, skipId)

  get: (key) -> @mongooseModel.get(key)

  set: (key, val) -> @mongooseModel.set(key, val)

  getId: -> @mongooseModel._id

  firstQueryFn = (parentId) ->
    query = {}
    query[parentId] = @getId()
    query


module.exports = MongoModelInstance
