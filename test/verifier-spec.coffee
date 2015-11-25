shmock = require 'shmock'
Verifier = require '../src/verifier'
MockMeshbluCoap = require './mock-meshblu-coap'

describe 'Verifier', ->
  beforeEach (done) ->
    @handlers = {}
    onConnection = (req, res) =>
      res.setOption 'Content-Format', 'application/json'

      if req.url == '/devices'
        @handlers.registerHandler req, res

      if req.url == '/whoami'
        @handlers.whoamiHandler req, res

      if req.url == '/devices/device-uuid'
        @handlers.unregisterHandler req, res

    @meshblu = new MockMeshbluCoap port: 0xd00d, onConnection: onConnection
    @meshblu.start done

  afterEach (done) ->
    @meshblu.stop => done()

  describe '-> verify', ->
    context 'when everything works', ->
      beforeEach ->
        meshbluConfig = server: 'localhost', port: 0xd00d
        @sut = new Verifier {meshbluConfig}

      beforeEach (done) ->
        @handlers.registerHandler = @registerHandler = sinon.spy (req, res) =>
          res.code = '2.01'
          res.end JSON.stringify uuid: 'device-uuid'

        @handlers.whoamiHandler = @whoamiHandler = sinon.spy (req, res) =>
          res.code = '2.00'
          res.end JSON.stringify uuid: 'device-uuid', type: 'meshblu:verifier'

        @handlers.unregisterHandler = @unregisterHandler = sinon.spy (req, res) =>
          res.code = '2.04'
          res.end()

        @sut.verify (@error) =>
          done @error

      it 'should not error', ->
        expect(@error).not.to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called
        expect(@unregisterHandler).to.be.called

    context 'when register fails', ->
      beforeEach ->
        meshbluConfig = server: 'localhost', port: 0xd00d
        @sut = new Verifier {meshbluConfig}

      beforeEach (done) ->
        @handlers.registerHandler = @registerHandler = sinon.spy (req, res) =>
          res.code = '5.00'
          res.end()

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called

    context 'when whoami fails', ->
      beforeEach ->
        meshbluConfig = server: 'localhost', port: 0xd00d
        @sut = new Verifier {meshbluConfig}

      beforeEach (done) ->
        @handlers.registerHandler = @registerHandler = sinon.spy (req, res) =>
          res.code = '2.01'
          res.end JSON.stringify uuid: 'device-uuid'

        @handlers.whoamiHandler = @whoamiHandler = sinon.spy (req, res) =>
          res.code = '5.00'
          res.end()

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called

    context 'when unregister fails', ->
      beforeEach ->
        meshbluConfig = server: 'localhost', port: 0xd00d
        @sut = new Verifier {meshbluConfig}

      beforeEach (done) ->
        @handlers.registerHandler = @registerHandler = sinon.spy (req, res) =>
          res.code = '2.01'
          res.end JSON.stringify uuid: 'device-uuid'

        @handlers.whoamiHandler = @whoamiHandler = sinon.spy (req, res) =>
          res.code = '2.00'
          res.end JSON.stringify uuid: 'device-uuid', type: 'meshblu:verifier'

        @handlers.unregisterHandler = @unregisterHandler = sinon.spy (req, res) =>
          res.code = '5.00'
          res.end()

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called
        expect(@unregisterHandler).to.be.called
