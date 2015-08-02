{_, Caches} = require('./dependencies')


class ModelContainer
  constructor: (@opts={}) ->
    @protos = {}
    @models = {}
    @caches = new Caches()

  addPrototype: (Proto, name, args...) ->
    if @protos[name]
      throw new Error("A prototype already exists named #{name}.")
    cache = @cs.new(name)
    factoryArgs = [Proto, @protos, name, cache].concat(args)
    ProtoFactory = Proto.bind.apply(Proto, factoryArgs)
    @protos[name] = new ProtoFactory()

  buildAncestorRelationships: (protosChain) ->
    protosChain
      .map (model) -> model.addAncestors()
      .every()
      .value()

  buildParentRelationships: (protosChain) ->
    protosChain
      .forEach (model) -> model.initParents()
      .value()

  buildAllAncestorRelationships: (protosChain) ->
    allRelationshipsBuilt = false
    until allRelationshipsBuilt
      allRelationshipsBuilt = @buildAncestorRelationships(protosChain)

  buildAllChildRelationships: (protosChain) ->
    protosChain
      .forEach (model) -> model.buildAllChildRelationships()
      .value()

  buildAllRelationships: ->
    protosChain = _.chain(@protos)
    @buildParentRelationships(protosChain)
    @buildAllAncestorRelationships(protosChain)
    @buildAllChildRelationships(protosChain)

  build: ->
    @buildAllRelationships()
    _.map @protos, (name, proto) => @models[name] = proto.toModel()


module.exports = Models
