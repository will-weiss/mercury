{_, CacheController} = require('../dependencies')

class ModelWrapper

  constructor: (@modelWrappers, @name, @model, @opts={}) ->
    @opts.batchWait ?= 1
    @cache = @modelWrappers.cc.new(name)
    @batcher = new this.Batcher(model, @opts.batchWait)

  findById: (id) ->
    cacheHit = @cache.get(id)
    return cacheHit if cacheHit isnt undefined
    fetch = batcher.by(id)
    cache.set(id, fetch)
    return fetch

class ModelWrappers

  constructor: (@opts={}) ->
    @models = {}
    @cc = new CacheController()

  register: (name, model, opts) ->
    _.defaults(opts, @opts)
    @models[name] = new this.ModelWrapper(@, name, model, opts)

module.exports = ModelWrappers
