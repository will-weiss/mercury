{mongoose} = require('../dependencies')

model = require('./model')

class MongoConnection
  constructor: (@connectionString) ->

  connect: ->
    return new Promise (resolve, reject) =>
      conn = @connection = mongoose.createConnection(@connectionString)

      conn.on 'error', (err) ->
        logger.log('error', err)
        reject(err)

      conn.on 'connected', ->
        logger.info 'Successfully connected to mongodb'
        resolve(conn)

      conn.on 'close', ->
        logger.info 'Mongo connection closed'

  model: (modelName, schema, opts={}) ->
    model(@connection, modelName, schema, opts)

module.exports = MongoConnection
