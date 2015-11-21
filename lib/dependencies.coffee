# This module exports the dependencies of mercury.
dependencies = module.exports

# Dependencies listed in a non-circular resolution order.
dependencyList = [

  # node_modules
  'bluebird::Promise'
  'body-parser::bodyParser'
  'cookie-parser::cookieParser'
  'express'
  'express-graphql::graphqlHTTP'
  'express-session::session'
  'fs'
  'graphql'
  'i'
  'lodash::_'
  'mongoose'

  # mercury
  './utils'
  './Queryable'
  './Caches'
  './Batcher'
  './createSchema'
  './Link'
  './buildModels'
  './Model'
  './Driver'
  './Application'
  './Mongo'
]

# Load dependencies.
dependencyList.forEach (dependency) ->
  [loc, name] = dependency.split('::')
  name ||= loc.split('/').pop()
  dependencies[name] = require(loc)
