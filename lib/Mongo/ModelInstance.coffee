{_, ModelInstance} = require('../dependencies')

class MongoModelInstance extends ModelInstance

  get: (key) -> @mongooseModel.get(key)

  set: (key, val) -> @mongooseModel.set(key, val)

  getId: -> @mongooseModel._id

  genFirstQuery = (parentId) ->
    query = {}
    query[parentId] = @getId()
    query


module.exports = MongoModelInstance
