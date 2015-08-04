{Batcher, utils} = require('../dependencies')

class MongoModelBatcher extends Batcher
  getList: (ids) ->
    utils.toFlood(@Model.MongooseModel.find({_id: {$in: ids}}).stream())
      .forEach(@resolveOne.bind(@))


module.exports = MongoModelBatcher
