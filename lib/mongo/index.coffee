{mongoose, Promise, Driver, Application} = require('../dependencies')

class MongoDriver extends Driver
  type: 'Mongo'
  Model: require('./Model')
  defaults:
    ownMongoose: true

  constructor: (app, name, opts) ->
    super app, name, opts
    @mongoose = if @opts.ownMongoose then new mongoose.Mongoose() else mongoose
    Promise.promisifyAll(@mongoose.Model)
    Promise.promisifyAll(@mongoose.Model.prototype)

  createConnection: ->
    conn = @mongoose.createConnection(@opts.connectionString)

    conn.on 'connected', =>
      @connected.resolve(conn)

    conn.on 'error', (err) =>
      @connected.reject(err)


Application.includeDriver(MongoDriver)
