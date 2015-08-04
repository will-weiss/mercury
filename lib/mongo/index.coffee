{mongoose, Promise, Driver} = require('../dependencies')

class MongoDriver extends Driver
  Model: require('./Model')

  constructor: (app, opts) ->
    super app, opts
    @mongoose = new mongoose.Mongoose()
    @mongoose = mongoose
    Promise.promisifyAll(@mongoose.Model)
    Promise.promisifyAll(@mongoose.Model.prototype)
    @connected = Promise.pending()

  connect: ->
    @connection = conn = @mongoose.createConnection(@connectionString)

    conn.on 'connected', =>
      @onConnectionSuccess()
      @connected.resolve()

    conn.on 'error', (err) =>
      @onConnectionError(err)
      @connected.reject(err)

    conn.on('close', @onConnectionClose.bind(@))

    @connected.promise

  model: (name, schema, opts) ->
    Model = super name, opts
    Model.MongooseModel = @mongoose.model(name, schema)
    Model


module.exports = Driver.drivers.Mongo = MongoDriver
