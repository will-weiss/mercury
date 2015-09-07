{Batcher} = require('../dependencies')

class MongoModelBatcher extends Batcher
  getList: (ids) ->
    new Promise (resolve, reject) =>
      stream = @batcher.Model.MongooseModel.find({_id: {$in: ids}}).stream()
      stream.on('error', reject)
      stream.on('close', resolve)
      stream.on('data', @resolveOne.bind(@))

module.exports = MongoModelBatcher
