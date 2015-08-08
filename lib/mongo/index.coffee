{mongoose, Promise, Driver} = require('../dependencies')

class MongoDriver extends Driver
  Model: require('./Model')

  constructor: (app, opts) ->
    super app, opts
    @schemas = {}
    @mongoose = new mongoose.Mongoose()
    Promise.promisifyAll(@mongoose.Model)
    Promise.promisifyAll(@mongoose.Model.prototype)
    @connected = Promise.pending()

  connect: ->
    @connection = @mongoose.createConnection(@connectionString)
    conn = @connection
    conn.on 'connected', =>
      for name, model of @models
        model.MongooseModel = conn.model(name, @schemas[name])
      @onConnectionSuccess()
      @connected.resolve()

    conn.on 'error', (err) =>
      @onConnectionError(err)
      @connected.reject(err)

    conn.on('close', @onConnectionClose.bind(@))

    @connected.promise

  model: (name, schema, opts) ->
    model = super name, opts
    @schemas[name] = schema
    model


module.exports = Driver.drivers.Mongo = MongoDriver
