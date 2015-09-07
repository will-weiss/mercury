{_, i, utils, Queryable} = require('./dependencies')

{pluralize} = i()


# A queryable entity corresponding with a persistent resource.
class Model extends Queryable
  constructor: (@app, name, @opts={}) ->
    super name
    # A batcher for this model is constructed.
    @batcher = new this.Batcher(@)
    # A cache is created from the app's caches.
    @cache = @app.caches.new(@name)
    # How the model appears as a singular and as a plural.
    {@appearsAsSingular, @appearsAsPlural} = @opts
    # By default, the model appears as its camelCase name.
    @appearsAsSingular ||= _.camelCase(@name)
    @appearsAsPlural ||= pluralize(@appearsAsSingular)

    # Relationships between other models of the app are maintained.
    @relationships = {child: {}, parent: {}, sibling: {}}

  # Find an instance of this model by id. If an instance can be retrieved from
  # the cache it is returned. Otherwise, a request is made to the batcher and
  # the promise for that request is set in the cache and returned.
  findById: (id) ->
    cacheHit = @cache.get(id)
    return cacheHit if cacheHit isnt undefined
    fetched = @batcher.by(id)
    @cache.set(id, fetched)
    fetched


# The prototype of a model must implement the functions below.
utils.mustImplement(
  Model, 'find', 'count', 'distinct', 'distinctIds', 'init', 'formQuery',
    'get', 'set', 'getId'
)

module.exports = Model
