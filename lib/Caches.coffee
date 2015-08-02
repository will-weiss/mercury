class Slot
  constructor: (@cs) ->
    @init()

  init: ->
    @cached = undefined
    @id = undefined
    @val = undefined

  set: (cached, id, @val) ->
    delete @cached[@id] if @cached isnt undefined
    @cached = cached
    @id = id
    @cached[@id] = @
    @cs.keep.push(@)
    return

  unset: ->
    if @val isnt undefined
      delete @cached[@id]
      @init()
      @cs.free.push(@)
    return


class Cache
  constructor: (@cs) ->
    @cached = {}

  get: (id) ->
    @cached[id]?.val

  set: (id, val) ->
    return if val is undefined
    @cs.getSlot().set(@cached, id, val)

  unset: (id) ->
    @cached[id]?.unset()


class Caches
  constructor: (size = 10000, exptime = 10000) ->
    @init()
    @run(size, exptime)

  init: ->
    @size = 0
    @caches = {}
    @free = []
    @keep = []
    @old = []
    return

  run: (size, @exptime) ->
    size = Math.max(size, 0)
    @insertSlot() for i in [0...size]
    @timer = setInterval(@expire.bind(@), @exptime)
    return

  new: (name) ->
    @caches[name] = new Cache(@)

  insertSlot: ->
    @size++
    @free.push(new Slot(@))
    return

  getSlot: ->
    @free.shift() || @old.shift() || @keep.shift()

  expire: ->
    slot.unset() for slot in @old
    @old = @keep
    @keep = []
    return

  kill: ->
    clearInterval(@timer)
    for name, cache of @caches
      cache.cached = null
      cache.getSlot = ->
      cache.get = ->
      cache.set = ->
    @init()


module.exports = Caches
