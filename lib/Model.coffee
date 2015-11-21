{_, i, utils, Batcher, Queryable} = require('./dependencies')

{pluralize} = i()


# A queryable entity corresponding with a persistent resource.
class Model extends Queryable
  constructor: (@driver, name) ->
    super name
    {@app} = @driver
    # A batcher for this model is constructed.
    @batcher = new Batcher(@)
    # A cache is created from the app's caches.
    @cache = @app.caches.new(@name)
    # By default, the model appears as its camelCase name.
    @appearsAsSingular = _.camelCase(@name)
    @appearsAsPlural = pluralize(@appearsAsSingular)
    # Relationships between other models of the app are maintained.
    @relationships = {child: {}, parent: {}, sibling: {}}

  # Find an instance of this model by id. If an instance can be retrieved from
  # the cache it is returned. Otherwise, a request is made to the batcher and
  # the promise for that request is set in the cache and returned.
  findById: (id) ->
    cacheHit = @cache.get(id)
    return Promise.resolve(cacheHit) if cacheHit isnt undefined
    fetched = @batcher.by(id)
    @cache.set(id, fetched)
    fetched

  # Create an instance from a supplied document. Set the created instance on the
  # cache.
  create: (doc) ->
    creationPromise = @createInstance(doc)
    creationPromise.then (created) => @cache.set(@getId(created), created)
    creationPromise

  # Remove an instance given its id. Set the id as null on the cache.
  remove: (id) ->
    @cache.set(id, null)
    @removeInstance(id)

  # Update an instance. Set the promised update on the cache.
  update: (id, updates) ->
    updatePromise = @updateInstance(id, updates)
    @cache.set(id, updatePromise)
    updatePromise


# The prototype of a model must implement the functions below.
utils.mustImplement(
  Model, 'createInstance', 'count', 'distinct', 'distinctIds', 'find',
    'findByIds', 'formQuery', 'get', 'getId', 'init', 'removeInstance', 'set',
    'updateInstance'
)

module.exports = Model
