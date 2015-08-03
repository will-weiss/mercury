{_, Caches} = require('./dependencies')


class ProtoContainer
  constructor: ->
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

  buildAncestorRelationships: (protos) ->
    _.chain(protos)
      .map (proto) -> proto.addAncestors()
      .every()
      .value()

  buildParentRelationships: (protos) ->
    protos.forEach (proto) => proto.initParents(@protos)

  buildAllAncestorRelationships: (protos) ->
    allRelationshipsBuilt = false
    until allRelationshipsBuilt
      allRelationshipsBuilt = @buildAncestorRelationships(protos)

  buildAllChildRelationships: (protos) ->
    protos.forEach (proto) -> proto.buildAllChildRelationships()

  buildAllFindFns: (protos) ->
    protos.forEach (proto) -> proto.buildAllFindFns()

  buildAllProtos: ->
    protos = _.values(@protos)
    @buildParentRelationships(protos)
    @buildAllAncestorRelationships(protos)
    @buildAllChildRelationships(protos)
    @buildAllFindFns(protos)

  buildModels: ->
    @buildAllProtos()
    _.map @protos, (proto, name) => @models[name] = proto.toModel()
    @models


module.exports = ProtoContainer
