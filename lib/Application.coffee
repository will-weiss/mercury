{ _, bodyParser, cookieParser, express, expressSession, defaults
, ProtoContainer, Driver, Caches } = require('./dependencies')

class Application
  constructor: (@opts) ->
    _.defaults(@opts, defaults.application)
    @express = express()
    @drivers = []
    @caches = new Caches()
    @protoContainer = new ProtoContainer(@)
    @models = {}

  addDriver: (type, opts) ->
    new Driver.drivers[type](@, opts)

  configure: ->
    @express.set('port', @opts.port)
    @express.use(express.static(@opts.static)) if @opts.static
    @express.use(bodyParser({ limit: @opts.fileLimit }))
    @express.use(bodyParser.urlencoded({extended:true}))
    @express.use(cookieParser())

  run: ->


module.exports = Application

