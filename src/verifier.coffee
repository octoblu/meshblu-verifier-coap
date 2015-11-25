async = require 'async'
MeshbluCoap = require 'meshblu-coap'

class Verifier

  constructor: ({meshbluConfig}) ->
    @meshbluCoap = new MeshbluCoap meshbluConfig

  _register: (callback) =>
    @meshbluCoap.register type: 'meshblu:verifier', (error, @device) =>
      return callback error if error?
      @meshbluCoap.uuid = @device.uuid
      @meshbluCoap.token = @device.token
      callback()

  _whoami: (callback) =>
    @meshbluCoap.whoami callback

  _unregister: (callback) =>
    return callback() unless @device?
    @meshbluCoap.unregister @device.uuid, callback

  verify: (callback) =>
    async.series [
      @_register
      @_whoami
      @_unregister
    ], callback

module.exports = Verifier
