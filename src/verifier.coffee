async = require 'async'
MeshbluCoap = require 'meshblu-coap'

class Verifier
  constructor: ({meshbluConfig,@nonce}) ->
    @nonce ?= Date.now()
    @meshblu = new MeshbluCoap meshbluConfig

  _register: (callback) =>
    @meshblu.register type: 'meshblu:verifier', (error, @device) =>
      return callback error if error?
      @meshblu.uuid = @device.uuid
      @meshblu.token = @device.token
      callback()

  _message: (callback) =>
    @meshblu.subscribe uuid: @meshblu.uuid, (error, @stream) =>
      return callback error if error?
      @stream.once 'data', (data) =>
        return callback new Error 'wrong message received' unless data?.payload == @nonce
        callback()

      message =
        devices: [@meshblu.uuid]
        payload: @nonce

      @meshblu.message message

  _update: (callback) =>
    return callback() unless @device?

    params =
      nonce: @nonce

    @meshblu.update @meshblu.uuid, params, (data) =>
      return callback new Error data.error if data?.error?
      @meshblu.whoami (data) =>
        return callback new Error 'update failed' unless data?.nonce == @nonce
        callback()

  _whoami: (callback) =>
    @meshblu.whoami callback

  _unregister: (callback) =>
    return callback() unless @device?
    @meshblu.unregister @device.uuid, callback

  verify: (callback) =>
    async.series [
      @_register
      @_whoami
      @_message
      @_update
      @_unregister
    ], callback

module.exports = Verifier
