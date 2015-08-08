{_, i, utils, graphql, createSchema} = require('./dependencies')

{pluralize} = i()

{mustImplement} = utils

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
    @schema = if @opts.isRoot then createSchema(@) else null

  findById: (id) ->
    cacheHit = @cache.get(id)
    return cacheHit if cacheHit isnt undefined
    fetched = @batcher.by(id)
    @cache.set(id, fetched)
    fetched

utils.mustImplement(
  Model, 'find', 'count', 'distinct', 'distinctIds', 'getAppearsAs',
    'getParentIdFields', 'getFields', 'formQuery', 'get', 'set', 'getId'
)


module.exports = Model
