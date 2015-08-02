{_, Caches} = require('./dependencies')


class Models
  constructor: (@opts={}) ->
    @models = {}
    @caches = new Caches()

  new: (Model, name, args...) ->
    if @models[name]
      throw new Error("A model already exists named #{name}.")
    cache = @cs.new(name)
    modelFactoryArgs = [Model, name, cache].concat(args)
    ModelFactory = Model.bind.apply(Model, modelFactoryArgs)
    @models[name] = new ModelFactory()

  buildParentRelationships: (modelsChain) ->
    modelsChain
      .map (model) -> model.addAncestors()
      .every()
      .value()

  buildAllParentRelationships: (modelsChain) ->
    allRelationshipsBuilt = false
    until allRelationshipsBuilt
      allRelationshipsBuilt = @buildParentRelationships(modelsChain)

  buildAllChildRelationships: (modelsChain) ->
    modelsChain
      .forEach (model) -> model.buildAllChildRelationships()
      .value()

  buildAllRelationships: ->
    modelsChain = _.chain(@models)
    @buildAllParentRelationships(modelsChain)
    @buildAllChildRelationships(modelsChain)


module.exports = Models
