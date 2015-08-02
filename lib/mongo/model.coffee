{mongoose, cacheWrap} = require('../dependencies')

module.exports = (connection, modelName, schema, opts={}) ->
  # addEncryptionHooks(schema)
  if opts.isProduction
    schema.pre "save", no_write
    schema.pre "remove", no_write
  model = connection.model(modelName, schema)
  model.findCache = cacheWrap(modelName, model)
  model
