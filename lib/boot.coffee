###
 * Boot the application server.
 *
 * Steps are:
 * 1) Load dependencies
 * 2) Connect to the databases
 * 3) Load mongoose models into memory
 * 4) Configure application
 * 5) Register module-specific endpoints
 * 6) Global error handling
 * 7) Start the server
 *
 * @returns promise<Express App>
###

###
 * makes DEPENDENCIES available as a global object
###
require('./dependencies')

{ Q, utils, _, express, bodyParser, cookieParser, config,
  expressSession, connectMongo, auth, mongo, multipart, models,
  graphQLSchemas, controllers} = DEPENDENCIES

MongoStore = connectMongo(expressSession)

secret = config.get('SESSION_SECRET') || 'changeme'

FILE_LIMIT = config.get('FILE_LIMIT')

CWD = process.cwd()

APPS = { export: null }

global.send405 = (req, res) -> res.status(405).send()

class Application

  # The deferred resolves with the app
  constructor: ->
    @deferred = Promise.pending()

  connectAndLoadModels: ->
    return mongo.connect().then =>
      logger.info 'Connected to mongo'
      # Models are loaded after mongo has connected.
      models.load()
      logger.info('Loaded models into memory')
      graphQLSchemas.load()
      logger.info('GraphQL loaded')
    .catch (err) =>
      @onError(err, 'Something failed during mongo connect: %s')

  determinePort: ->
    # Define the port the server will run on. Process can be run with PORT in
    # environment variable to run on a different port. Defaults to 8090 or 8001
    # if in a test environment.
    try
      @PORT = if IN_TEST_ENV then 8001 else (process.env.PORT || 8090)
    catch err
      @onError(err, 'Failed to determine port: %s')

  configureExpress: ->
    try
      ###
       * Express application configuration
      ###
      @app.set('port', @PORT)
      @app.set('views', "#{CWD}/views")
      @app.use(express.static("#{CWD}/public"))
      @app.use(bodyParser({ limit: FILE_LIMIT }))
      @app.use(bodyParser.urlencoded({extended:true}))
      @app.use(cookieParser())
      @app.use(multipart())
      # Session
      store = new MongoStore
        mongoose_connection: mongo.connections.local.connection
      @app.use expressSession({ secret, store })
      logger.log('Set application configuration')

    catch err
      @onError(err, 'Failed to set app configuration: %s')

  # Register all the controllers
  registerControllers: ->
    controllers.load(@app)

  # Error handling is the last thing in the stack
  configureAppErrorHandling: ->
    logger.info("Configuring error handling for app")
    @app.use (err, req, res, next) ->
      logger.error(err.message)
      res.status(500)
      res.send(err.stack)

  # Finally, start the server
  startServer: ->
    @app.server = @app.listen @PORT, =>
      logger.info('Express server listening on port %d', @PORT)
      @deferred.resolve(@app)

  onError: (err, prefix) ->
    console.log 'CAUGHT ERROR'
    console.error err
    logger.reportError(err)
    logger.error(prefix, err.message) if prefix
    @deferred.reject(err)

  addRebootEndpoint: ->
    return @app.get '/api/reboot', auth.requireLogin, (req, res) ->
      res.status(200).send(null)
      boot(true)

  attemptBoot: ->
    @app = express()
    @connectAndLoadModels().then =>
      @determinePort()
      @configureExpress()
      @registerControllers()
    .then =>
      @configureAppErrorHandling()
      @startServer()
      @addRebootEndpoint()
    .catch @onError.bind(@)

boot = (reboot = false) ->
  # if there is no application to export, create one and attempt to boot it
  if not APPS.export?
    APPS.export = new Application()
    APPS.export.attemptBoot()

  # If there is an existing application and a reboot is desired create a new
  # application, but only attempt to boot it after the old application's server
  # closes.
  else if reboot
    logger.info("Rebooting application...")
    APPS.old = APPS.export
    APPS.export = new Application()

    APPS.old.deferred.promise.then (app) =>
      logger.info("Closing existing server...")
      app.server.close =>
        delete APPS.old
        logger.info("Existing server closed, attempting to boot...")
        APPS.export.attemptBoot()
    .catch _.noop

  # Return the promised application
  return APPS.export.deferred.promise

module.exports = boot
