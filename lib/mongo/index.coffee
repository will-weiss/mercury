{mongoose, Driver} = require('../dependencies')

class MongoDriver extends Driver

  connect: ->
    return new Promise (resolve, reject) =>
      conn = @connection = mongoose.createConnection(@connectionString)

      conn.on 'connected', =>
        @onConnectionSuccess()
        resolve(conn)

      conn.on 'error', (err) =>
        @onConnectionError(err)
        reject(err)

      conn.on('close', @onConnectionClose.bind(@))

  model: (name, schema) ->
    mongooseModel = @connection.model(name, schema)




MongoDriver.ModelProto = require('./ModelProto')

module.exports = Driver.drivers.Mongo = MongoDriver
