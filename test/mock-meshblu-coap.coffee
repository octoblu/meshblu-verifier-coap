coap = require 'coap'

class MockMeshbluCoap
  constructor: (options) ->
    {@onConnection, @port} = options

  start: (callback) =>
    @server = coap.createServer()
    @server.on 'request', @onConnection
    @server.listen @port, callback

  stop: (callback) =>
    @server.close callback

module.exports = MockMeshbluCoap
