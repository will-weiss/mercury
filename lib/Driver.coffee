{_, utils, Promise} = require('./dependencies')

class Driver
  constructor: (@app, @name, @opts) ->
    @index = @app.drivers.length
    unless @opts
      @opts = @name
      @name = "Driver ##{@index + 1}"

    _.defaults(@opts, @defaults) if @defaults
    @models = {}
    @connection = null
    @connected = Promise.pending()

  connect: ->
    @createConnection()

    @connected.promise.then (conn) =>
      @connection = conn
      if @app.opts.verbose
        console.log("#{@name} connected.")
      if @opts.models
        @model(name, opts) for name, opts of @opts.models
      conn
    # .catch (err) =>
    #   console.error("#{@name} failed to connect.")
    #   throw err

  model: (name, args...) ->
    @app.models[name] = @models[name] = new @Model(@, name, args...)


utils.mustImplement(Driver, 'Model', 'connect')

module.exports = Driver
