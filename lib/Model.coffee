{_, i, utils, graphql, createSchema} = require('./dependencies')

{pluralize} = i()

{mustImplement} = utils

class Model
  constructor: (@app, @name, @opts={}) ->
    @batcher = new this.Batcher(@)
    @cache = @app.caches.new(@name)
    {@appearsAsSingular, @appearsAsPlural} = @opts
    # Get how the model appears as a singular if not otherwise specified.
    @appearsAsSingular ||= @getAppearsAs()
    # Get how the model appears as a plural if not otherwise specified.
    @appearsAsPlural ||= pluralize(@appearsAsSingular)
    @basicFields = {}
    @fields = {}
    @relationships = {child: {}, parent: {}, sibling: {}}
    @objectType = new graphql.GraphQLObjectType
      name: @name
      description: @appearsAsSingular
      fields: @fields
    @listType = new graphql.GraphQLList(@objectType)
    @parentNameToParentId = null

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
