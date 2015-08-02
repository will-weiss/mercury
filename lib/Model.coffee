{_} = require('./dependencies')

class Model
  constructor: ->

  findById: (id) ->
    cacheHit = @cache.get(id)
    return cacheHit if cacheHit isnt undefined
    fetched = batcher.by(id)
    cache.set(id, fetched)
    fetched


module.exports = Model
