{Application, Driver, Model, mongoose} = require('./dependencies')

module.exports = exports = (opts) -> new Application(opts)

exports.Application = Application
exports.Driver = Driver
exports.Model = Model
exports.mongoose = mongoose
