{ _, bodyParser, cookieParser, express, expressSession, LaterList, defaults
, buildModels, ProtoContainer, Driver, Caches } = require('./dependencies')

class Application
  constructor: (@opts) ->
    _.defaults(@opts, defaults.application)
    @express = express()
    @drivers = []
    @caches = new Caches()
    @Models = {}

  addDriver: (type, opts) ->
    driver = new Driver.drivers[type](@, opts)
    @drivers.push(driver)
    driver

  configure: ->
    @express.set('port', @opts.port)
    @express.use(express.static(@opts.static)) if @opts.static
    @express.use(bodyParser({ limit: @opts.fileLimit }))
    @express.use(bodyParser.urlencoded({extended:true}))
    @express.use(cookieParser())

  run: ->
    LaterList.Relay.from(@drivers)
      .forEach (driver) => driver.connect()
      .then =>
        buildModels(@Models)
        console.log @Models


module.exports = Application

