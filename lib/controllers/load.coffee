{utils, Controller} = DEPENDENCIES

dir = "#{__dirname}/controllers"

load = (controllers, app) ->
  Controller::app = app
  for nm, Ctrl of utils.requireAll(dir)
    controllers[nm] = new Ctrl()

module.exports = load
