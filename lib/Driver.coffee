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

  model: (name) ->
    @app.models[name] = @models[name] = new this.Model(@app, name)


Driver.drivers = {}

utils.ctorMustImplement(Driver, 'Model')
utils.protoMustImplement(Driver, 'connect')

module.exports = Driver
