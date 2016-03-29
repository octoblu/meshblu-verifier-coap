shmock = require 'shmock'
Verifier = require '../src/verifier'
MockMeshbluCoap = require './mock-meshblu-coap'

describe 'Verifier', ->
  beforeEach (done) ->
    @handlers = {}
    onConnection = (req, res) =>
      res.setOption 'Content-Format', 'application/json'

      if req.code == '0.02' && req.url == '/devices'
        @handlers.registerHandler req, res

      if req.code == '0.01' && req.url == '/whoami'
        @handlers.whoamiHandler req, res

      if req.code == '0.04' && req.url == '/devices/device-uuid'
        @handlers.unregisterHandler req, res

      if req.code == '0.03' && req.url == '/devices/device-uuid'
        @handlers.updateHandler req, res

      if req.code == '0.01' && req.url == '/subscribe/device-uuid?'
        @handlers.subscribeHandler req, res

      if  req.code == '0.02' && req.url == '/messages'
        @handlers.messagesHandler req, res

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
          res.code = '2.05'
          if @updateContents?
            return res.end @updateContents
          res.end JSON.stringify uuid: 'device-uuid', type: 'meshblu:verifier'

        @handlers.subscribeHandler = @subscribeHandler = sinon.spy (req, res) =>
          res.code = '2.05'
          res.write JSON.stringify(subscribed: true) + '\n'
          @subscribeRes = res

        @handlers.messagesHandler = @messagesHandler = sinon.spy (req, res) =>
          res.code = '2.05'
          res.end()
          @subscribeRes.write req._packet.payload

        @handlers.unregisterHandler = @unregisterHandler = sinon.spy (req, res) =>
          res.code = '2.02'
          res.end()

        @handlers.updateHandler = @updateHandler = sinon.spy (req, res) =>
          res.code = '2.05'
          @updateContents = req._packet.payload
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

    context 'when message fails', ->
      beforeEach ->
        meshbluConfig = server: 'localhost', port: 0xd00d
        @sut = new Verifier {meshbluConfig}

      beforeEach (done) ->
        @handlers.registerHandler = @registerHandler = sinon.spy (req, res) =>
          res.code = '2.01'
          res.end JSON.stringify uuid: 'device-uuid'

        @handlers.whoamiHandler = @whoamiHandler = sinon.spy (req, res) =>
          res.code = '2.05'
          if @updateContents?
            return res.end @updateContents
          res.end JSON.stringify uuid: 'device-uuid', type: 'meshblu:verifier'

        @handlers.subscribeHandler = @subscribeHandler = sinon.spy (req, res) =>
          res.code = '2.05'
          res.write JSON.stringify(subscribed: true) + '\n'
          @subscribeRes = res

        @handlers.messagesHandler = @messagesHandler = sinon.spy (req, res) =>
          res.code = '2.05'
          res.end()
          @subscribeRes.write '{}'

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called
        expect(@subscribeHandler).to.be.called
        expect(@messagesHandler).to.be.called

    context 'when update fails', ->
      beforeEach ->
        meshbluConfig = server: 'localhost', port: 0xd00d
        @sut = new Verifier {meshbluConfig}

      beforeEach (done) ->
        @handlers.registerHandler = @registerHandler = sinon.spy (req, res) =>
          res.code = '2.01'
          res.end JSON.stringify uuid: 'device-uuid'

        @handlers.whoamiHandler = @whoamiHandler = sinon.spy (req, res) =>
          res.code = '2.05'
          if @updateContents?
            return res.end @updateContents
          res.end JSON.stringify uuid: 'device-uuid', type: 'meshblu:verifier'

        @handlers.subscribeHandler = @subscribeHandler = sinon.spy (req, res) =>
          res.code = '2.05'
          res.write JSON.stringify(subscribed: true) + '\n'
          @subscribeRes = res

        @handlers.messagesHandler = @messagesHandler = sinon.spy (req, res) =>
          res.code = '2.05'
          res.end()
          @subscribeRes.write req._packet.payload

        @handlers.updateHandler = @updateHandler = sinon.spy (req, res) =>
          res.code = '2.05'
          @updateContents = {}
          res.end()

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called
        expect(@subscribeHandler).to.be.called
        expect(@messagesHandler).to.be.called
        expect(@updateHandler).to.be.called

    context 'when unregister fails', ->
      beforeEach ->
        meshbluConfig = server: 'localhost', port: 0xd00d
        @sut = new Verifier {meshbluConfig}

      beforeEach (done) ->
        @handlers.registerHandler = @registerHandler = sinon.spy (req, res) =>
          res.code = '2.01'
          res.end JSON.stringify uuid: 'device-uuid'

        @handlers.whoamiHandler = @whoamiHandler = sinon.spy (req, res) =>
          res.code = '2.05'
          if @updateContents?
            return res.end @updateContents
          res.end JSON.stringify uuid: 'device-uuid', type: 'meshblu:verifier'

        @handlers.subscribeHandler = @subscribeHandler = sinon.spy (req, res) =>
          res.code = '2.05'
          res.write JSON.stringify(subscribed: true) + '\n'
          @subscribeRes = res

        @handlers.messagesHandler = @messagesHandler = sinon.spy (req, res) =>
          res.code = '2.05'
          res.end()
          @subscribeRes.write req._packet.payload

        @handlers.updateHandler = @updateHandler = sinon.spy (req, res) =>
          res.code = '2.05'
          @updateContents = req._packet.payload
          res.end()

        @handlers.unregisterHandler = @unregisterHandler = sinon.spy (req, res) =>
          res.code = '5.00'
          res.end()

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called
        expect(@subscribeHandler).to.be.called
        expect(@messagesHandler).to.be.called
        expect(@updateHandler).to.be.called
        expect(@unregisterHandler).to.be.called
