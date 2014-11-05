{find} = require 'underscore-plus'
Serializable = require 'serializable'
BufferPatch = require './buffer-patch'
MarkerPatch = require './marker-patch'

# Contains several patches that we want to undo/redo as a batch.
module.exports =
class Transaction extends Serializable
  @registerDeserializers(BufferPatch, MarkerPatch)

  constructor: (@patches=[], groupingInterval=0) ->
    @groupingExpirationTime = Date.now() + groupingInterval

  serializeParams: ->
    patches: @patches.map (patch) -> patch.serialize()

  deserializeParams: (params) ->
    params.patches = params.patches.map (patchState) => @constructor.deserialize(patchState)
    params

  push: (patch) ->
    @patches.push(patch)

  invert: (buffer) ->
    new @constructor(@patches.map((patch) -> patch.invert(buffer)).reverse())

  applyTo: (buffer) ->
    patch.applyTo(buffer) for patch in @patches

  hasBufferPatches: ->
    find @patches, (patch) -> patch instanceof BufferPatch

  merge: (transaction) ->
    @push(patch) for patch in transaction.patches
    @groupingExpirationTime = transaction.groupingExpirationTime

  isOpenForGrouping: ->
    @groupingExpirationTime > Date.now()
