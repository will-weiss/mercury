{_, defaults, utils} = require('./dependencies')

class Driver
  constructor: (@app, opts) ->
    _.extend(opts, defaults.driver)
    _.extend(@, opts)
    @index = @app.drivers.length
    @name ||= "#{@type} driver #{@index + 1}"
    @models = {}

  onConnectionSuccess: ->
    console.log("#{@name} connected.")

  onConnectionError: (err) ->
    console.log("#{@name} failed to connect.")
    throw err

  onConnectionClose: ->
    console.log("#{@name} connection closed.")

  model: (name, opts) ->
    @app.models[name] = @models[name] = new this.Model(@app, name, opts)


Driver.drivers = {}

utils.mustImplement(Driver, 'Model', 'connect')


module.exports = Driver
