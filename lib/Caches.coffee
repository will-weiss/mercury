# A single value store. Slots are used by all caches as needed.
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


# Maps ids to slots. One may get, set, and unset values on the cache by id.
class Cache
  constructor: (@cs) ->
    @cached = {}

  get: (id) ->
    @cached[id]?.val

  set: (id, val) ->
    return if val is undefined
    return @cached[id].val = val if id of @cached
    @cs.getSlot().set(@cached, id, val)

  unset: (id) ->
    @cached[id]?.unset()


# Maintains caches and apportions pre-allocated slots as needed for each.
# Expires old slots on an interval.
class Caches
  constructor: (size = 50000, exptime = 10000) ->
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
