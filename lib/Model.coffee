{_, i, utils, graphql} = require('./dependencies')

{pluralize} = i()

{ctorMustImplement, protoMustImplement} = utils

class Model
  constructor: (@app, @name, @opts={}) ->

  init: ->
    @batcher = new this.Batcher(@)
    @cache = @app.caches.new(@name)
    {@appearsAsSingular, @appearsAsPlural} = @opts
    # Get how the model appears as a singular if not otherwise specified.
    @appearsAsSingular ||= @getAppearsAs()
    # Get how the model appears as a plural if not otherwise specified.
    @appearsAsPlural ||= pluralize(@appearsAsSingular)
    @relationships = {child: {}, parent: {}}
    @parentIdFields = @getParentIdFields()
    @fields = @getFields()
    @objectType = new graphql.GraphQLObjectType
      name: @name
      description: @appearsAsSingular
      fields: => @fields

  findById: (id) ->
    cacheHit = @cache.get(id)
    return cacheHit if cacheHit isnt undefined
    fetched = @batcher.by(id)
    @cache.set(id, fetched)
    fetched

module.exports = Model
