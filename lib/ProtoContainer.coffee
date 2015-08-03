{_, Caches} = require('./dependencies')


class ProtoContainer
  constructor: (@app) ->
    @protos = {}

  addProto: (Proto, name, args...) ->
    if @protos[name]
      throw new Error("A prototype already exists named #{name}.")
    cache = @app.caches.new(name)
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

  buildAllModels: ->
    @buildAllProtos()
    _.forEach @protos, (proto, name) => @app.models[name] = proto.toModel()


module.exports = ProtoContainer
