{LaterList} = require('./dependencies')

{Flood, Relay} = LaterList

toFlood = (stream) ->
  flood = new Flood()
  stream.on 'data', flood.push.bind(flood)
  stream.on 'error', flood.end.bind(flood)
  stream.on 'close', flood.end.bind(flood)
  return flood

accumQuery = (query, queryFn) -> queryFn(query)

reduceQueries = (firstQuery, queryFns) ->
  Relay.from(queryFns).reduce(accumQuery, firstQuery)

ctorMustImplement = (Ctor, fnNames...) ->
  fnNames.forEach (fnName) ->
    Ctor[fnName] = ->
      throw new Error("#{Ctor.name} must implement #{fnName}.")

protoMustImplement = (Ctor, fnNames...) ->
  fnNames.forEach (fnName) ->
    Ctor[fnName] = ->
      throw new Error("#{Ctor.name}.prototype must implement #{fnName}.")

module.exports = { toFlood, reduceQueries, accumQuery , ctorMustImplement
                 , protoMustImplement }
