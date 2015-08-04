{_, ModelInstance} = require('../dependencies')

class MongoModelInstance extends ModelInstance

  constructor: (doc, fields, skipId) ->
    @mongooseModel = new this.MongooseModel(doc, fields, skipId)

  get: (key) -> @mongooseModel.get(key)

  getId: -> @mongooseModel._id

  firstQueryFn = ->
    query = {}
    query[parentId] = @getId()
    query


module.exports = MongoModelInstance
