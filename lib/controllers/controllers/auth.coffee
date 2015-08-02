###
 * Authentication controller
 * @author Will Weiss <willweiss@maxwellhealth.com>
###

{auth, Controller} = DEPENDENCIES

class AuthController extends Controller
  route: '/api/auth'
  constructor: ->
    # POST: login
    @app.post @route, auth.authenticate.bind(auth)
    # DELETE: logout
    @addEndpoint 'del', @route, auth.logout.bind(auth)
    # GET: who's logged in?
    @addEndpoint 'get', @route, (req, res) -> res.status(200).send(req.user)

module.exports = AuthController
