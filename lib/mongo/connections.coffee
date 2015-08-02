{config} = DEPENDENCIES

MongoConnection = require('./connection')

class MongoConnections
  constructor: (@dbNames) ->
    @connections = {}

  connectOne: (dbName) ->
    upperName = dbName.toUpperCase()
    @connections[dbName] = new MongoConnection(connectionString)
    @connections[dbName].connect()

  connect: ->
    logger.info 'Connecting to databases'
    return Promise.all(@connectOne(d) for d in @dbNames)

  model: (dbName, modelName, schema, opts={}) ->
    @connections[dbName].model(modelName, schema, opts)

module.exports = MongoConnections
