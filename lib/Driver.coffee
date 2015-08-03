{_, defaults, utils} = require('./dependencies')

class Driver
  constructor: (@app, opts) ->
    _.extend(opts, defaults.driver)
    _.extend(@, opts)
    {drivers} = @app
    @index = drivers.length
    @name ||= "#{@type} driver #{@index + 1}"
    drivers.push(@)

  onConnectionSuccess: ->
    console.log("#{@name} connected.")

  onConnectionError: (err) ->
    console.log("#{@name} failed to connect.")
    throw err

  onConnectionClose: ->
    console.log("#{@name} connection closed.")

  addProto: (name, args...) ->
    {ModelProto} = @constructor
    factoryArgs = [ModelProto, name].concat(args)
    ProtoFactory = ModelProto.bind.apply(factoryArgs)
    @app.protos[name] = new ProtoFactory()

Driver.drivers = {}

utils.ctorMustImplement(Driver, 'ModelProto')
utils.protoMustImplement(Driver, 'connect')

module.exports = Driver
