# This module exports the dependencies of mercury.
dependencies = module.exports

# Dependencies listed in a non-circular resolution order.
dependencyList = [

  # node_modules
  'allong.es::allong'
  'bluebird::Promise'
  'body-parser::bodyParser'
  'cookie-parser::cookieParser'
  'connect-mongo::connectMongo'
  'express'
  'express-session::expressSession'
  'fs'
  'graphql'
  'i'
  'LaterList'
  'lodash::_'
  'moment'
  'mongoose'
  'require-all::requireAll'
  'util'
  'vers'
  'winston'

  # mercury
  './defaults'
  './utils'
  './Caches'
  './Batcher'
  './Driver'
  './Relationship'
  './buildRelationships'
  './buildGraphQLObjectTypes'
  './Model'
  './Mongo'
  './graphQL'
  './Controller'
  './controllers'
  './Application'
]

# Load a dependency
loadOne = (dependency) ->
  [loc, name] = dependency.split('::')
  name ?= loc.split('/').pop()
  dependencies[name] = require(loc)

# Load all dependencies
dependencies.load = ->
  delete dependencies.load
  dependencyList.forEach(loadOne)
  return dependencies
