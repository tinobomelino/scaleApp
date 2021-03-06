require?("./nodeSetup")()

describe "scaleApp core", ->

  pause = (ms) ->
    ms += (new Date).getTime()
    continue while ms > new Date()

  before ->

    if typeof(require) is "function"
      @scaleApp  = require "../src/scaleApp"
    else if window?
      @scaleApp  = window.scaleApp

    @validModule = (sb) ->
      init: (opt, done) -> setTimeout done, 0
      destroy: (done) -> setTimeout done, 0

  after ->
    @scaleApp.unregisterAll()

  it "provides the global and accessible namespace scaleApp", ->
    (expect typeof @scaleApp).toEqual "object"

  it "has a VERSION property", ->
    (expect typeof @scaleApp.VERSION).toEqual "string"

  describe "register function", ->

    it "is an accessible function", ->
      (expect typeof @scaleApp.register).toEqual "function"

    it "returns true if the module is valid", ->
      (expect @scaleApp.register "myModule", @validModule).toBeTruthy()

    it "returns false if the module creator is an object", ->
      (expect @scaleApp.register "myObjectModule", {}).toBeFalsy()

    it "returns false if the module creator does not return an object", ->
      (expect @scaleApp.register "myModuleIsInvalid", -> "I'm not an object").toBeFalsy()

    it "returns false if the created module object has not the functions init and destroy", ->
      (expect @scaleApp.register "myModuleOtherInvalid", ->).toBeFalsy()

    it "returns true if option parameter is an object", ->
      (expect @scaleApp.register "moduleWithOpt", @validModule, { } ).toBeTruthy()

    it "returns false if the option parameter is not an object", ->
      (expect @scaleApp.register "myModuleWithWrongObj", @validModule, "I'm not an object" ).toBeFalsy()

    it "returns false if module already exits", ->
      (expect @scaleApp.register "myDoubleModule", @validModule).toBeTruthy()
      (expect @scaleApp.register "myDoubleModule", @validModule).toBeFalsy()

  describe "list methods", ->

    beforeEach ->
      @scaleApp.stopAll()
      @scaleApp.unregisterAll()
      @scaleApp.register "myModule", @validModule

    it "has an lsModules method", ->
      (expect typeof @scaleApp.lsModules).toEqual "function"
      (expect @scaleApp.lsModules()).toEqual ["myModule"]

    it "has an lsInstances method", ->
      (expect typeof @scaleApp.lsInstances).toEqual "function"
      (expect @scaleApp.lsInstances()).toEqual []
      (expect @scaleApp.start "myModule" ).toBeTruthy()
      (expect @scaleApp.lsInstances()).toEqual ["myModule"]
      (expect @scaleApp.start "myModule", instanceId: "test" ).toBeTruthy()
      (expect @scaleApp.lsInstances()).toEqual ["myModule", "test"]
      (expect @scaleApp.stop "myModule").toBeTruthy()
      (expect @scaleApp.lsInstances()).toEqual ["test"]

    it "//has an ls method", ->

  describe "unregister function", ->

    it "returns true if the module was successfully removed", ->
      (expect @scaleApp.register "m", @validModule).toBeTruthy()
      (expect @scaleApp.unregister "m").toBeTruthy()
      (expect @scaleApp.start "m").toBeFalsy()

  describe "unregisterAll function", ->

    it "removes all modules", ->
      (expect @scaleApp.register "a", @validModule).toBeTruthy()
      (expect @scaleApp.register "b", @validModule).toBeTruthy()
      @scaleApp.unregisterAll()
      (expect @scaleApp.start "a").toBeFalsy()
      (expect @scaleApp.start "b").toBeFalsy()

  describe "start function", ->

    beforeEach ->
      @scaleApp.stopAll()
      @scaleApp.unregisterAll()
      @scaleApp.register "myId", @validModule

    afterEach -> @scaleApp.stop "myId"

    it "is an accessible function", ->
      (expect typeof @scaleApp.start).toEqual "function"

    describe "start parameters", ->

      it "returns false if first parameter is not a string or an object", ->
        (expect @scaleApp.start 123).toBeFalsy()
        (expect @scaleApp.start ->).toBeFalsy()
        (expect @scaleApp.start []).toBeFalsy()

      it "returns true if first parameter is a string", ->
        (expect @scaleApp.start "myId").toBeTruthy()

      it "returns true if second parameter is a an object", ->
        (expect @scaleApp.start "myId", {}).toBeTruthy()

      it "returns false if second parameter is a number", ->
        (expect @scaleApp.start "myId", 123).toBeFalsy()

      it "returns false if module does not exist", ->
        (expect @scaleApp.start "foo").toBeFalsy()

      it "returns true if module exist", ->
        (expect @scaleApp.start "myId").toBeTruthy()

      it "returns false if instance was aleready started", ->
        @scaleApp.start "myId"
        (expect @scaleApp.start "myId").toBeFalsy()

      it "calls the callback function after the initialization", (done) ->

        x     = 0
        cb    = -> (expect x).toBe(2); done()

        @scaleApp.register "anId", (sb) ->
          init: (opt, fini) ->
            setTimeout (-> x = 2; fini()), 0
            x = 1
          destroy: ->

        @scaleApp.start "anId", { callback: cb }

      it "calls the callback immediately if no callback was defined", ->
        cb = sinon.spy()
        mod1 = (sb) ->
          init: (opt) ->
          destroy: ->
        (expect @scaleApp.register "anId", mod1).toBeTruthy()
        @scaleApp.start "anId", { callback: cb }
        (expect cb).toHaveBeenCalled()

      it "calls the callback function with an error if an error occours", ->
        cb = sinon.spy()
        call = (err)->
          (expect err.message).toEqual "could not start module: thisWillProcuceAnError is not defined"
          cb()
        initCB = sinon.spy()
        mod1 = (sb) ->
          init: ->
            initCB()
            thisWillProcuceAnError()
          destroy: ->
        (expect @scaleApp.register "anId", mod1).toBeTruthy()
        (expect @scaleApp.start "anId", { callback: call }).toBeFalsy()
        (expect initCB).toHaveBeenCalled()
        (expect cb).toHaveBeenCalled()

      it "starts a separate instance", ->

        initCB = sinon.spy()
        mod1 = (sb) ->
          init: -> initCB()
          destroy: ->

        (expect @scaleApp.register "separate", mod1).toBeTruthy()
        @scaleApp.start "separate", { instanceId: "instance" }
        (expect initCB).toHaveBeenCalled()

  describe "startAll function", ->

    beforeEach ->
      @scaleApp.stopAll()
      @scaleApp.unregisterAll()

    it "is an accessible function", ->
      (expect typeof @scaleApp.startAll).toEqual "function"

    it "instantiates and starts all available modules", ->

      cb1 = sinon.spy()
      cb2 = sinon.spy()

      mod1 = (sb) ->
        init: -> cb1()
        destroy: ->

      mod2 = (sb) ->
        init: -> cb2()
        destroy: ->

      (expect @scaleApp.register "first", mod1 ).toBeTruthy()
      (expect @scaleApp.register "second", mod2).toBeTruthy()

      (expect cb1).not.toHaveBeenCalled()
      (expect cb2).not.toHaveBeenCalled()

      (expect @scaleApp.startAll()).toBeTruthy()
      (expect cb1).toHaveBeenCalled()
      (expect cb2).toHaveBeenCalled()

    it "starts all modules of the passed array", ->

      cb1 = sinon.spy()
      cb2 = sinon.spy()
      cb3 = sinon.spy()

      mod1 = (sb) ->
        init: -> cb1()
        destroy: ->

      mod2 = (sb) ->
        init: -> cb2()
        destroy: ->

      mod3 = (sb) ->
        init: -> cb3()
        destroy: ->

      @scaleApp.stopAll()
      @scaleApp.unregisterAll()

      (expect @scaleApp.register "first", mod1 ).toBeTruthy()
      (expect @scaleApp.register "second",mod2 ).toBeTruthy()
      (expect @scaleApp.register "third", mod3 ).toBeTruthy()

      (expect cb1).not.toHaveBeenCalled()
      (expect cb2).not.toHaveBeenCalled()
      (expect cb3).not.toHaveBeenCalled()

      (expect @scaleApp.startAll ["first","third"]).toBeTruthy()
      (expect cb1).toHaveBeenCalled()
      (expect cb2).not.toHaveBeenCalled()
      (expect cb3).toHaveBeenCalled()

    it "calls the callback function after all modules have started", (done) ->

      cb1 = sinon.spy()

      sync = (sb) ->
        init: (opt)->
          (expect cb1).not.toHaveBeenCalled()
          cb1()
        destroy: ->

      pseudoAsync = (sb) ->
        init: (opt, done)->
          (expect cb1.callCount).toEqual 1
          cb1()
          done()
        destroy: ->

      async = (sb) ->
        init: (opt, done)->
          setTimeout (->
            (expect cb1.callCount).toEqual 2
            cb1()
            done()
          ), 0
        destroy: ->

      @scaleApp.register "first", sync
      @scaleApp.register "second", async
      @scaleApp.register "third", pseudoAsync

      (expect @scaleApp.startAll ->
        (expect cb1.callCount).toEqual 3
        done()
      ).toBeTruthy()

    it "calls the callback after defined modules have started", (done) ->

      finished = sinon.spy()

      cb1 = sinon.spy()
      cb2 = sinon.spy()

      mod1 = (sb) ->
        init: (opt, done)->
          setTimeout done, 0
          (expect finished).not.toHaveBeenCalled()
        destroy: ->

      mod2 = (sb) ->
        init: (opt, done) ->
          setTimeout done, 0
          (expect finished).not.toHaveBeenCalled()
        destroy: ->

      @scaleApp.register "first", mod1, { callback: cb1 }
      @scaleApp.register "second", mod2, { callback: cb2 }

      (expect @scaleApp.startAll ["first","second"], ->
        finished()
        (expect cb1).toHaveBeenCalled()
        (expect cb2).toHaveBeenCalled()
        done()
      ).toBeTruthy()

    it "calls the callback with an error if one or more modules couldn't start", (done) ->
      spy1 = sinon.spy()
      spy2 = sinon.spy()
      mod1 = (sb) ->
        init: -> spy1(); thisIsAnInvalidMethod()
        destroy: ->
      mod2 = (sb) ->
        init: -> spy2()
        destroy: ->
      finished = (err) ->
        (expect err.message).toEqual "errors occoured in the following modules: 'invalid'"
        done()
      @scaleApp.register "invalid", mod1
      @scaleApp.register "valid", mod2
      (expect @scaleApp.startAll ["invalid", "valid"], finished).toBeFalsy()
      (expect spy1).toHaveBeenCalled()
      (expect spy2).toHaveBeenCalled()

    it "calls the callback with an error if one or more modules don't exist", (done) ->

      spy2 = sinon.spy()
      mod = (sb) ->
        init: (opt, done)->
          spy2()
          setTimeout done, 0
        destroy: ->
      @scaleApp.register "valid", @validModule
      @scaleApp.register "x", mod
      finished = (err) ->
        (expect err.message).toEqual "these modules don't exist: 'invalid','y'"
        done()
      (expect @scaleApp.startAll ["valid","invalid", "x", "y"], finished).toBeFalsy()
      (expect spy2).toHaveBeenCalled()

    it "calls the callback without an error if module array is empty", ->
      spy = sinon.spy()
      finished = (err) ->
        (expect err).toEqual null
        spy()
      (expect @scaleApp.startAll [], finished).toBeTruthy()
      (expect spy).toHaveBeenCalled()

  describe "stop function", ->

    beforeEach ->
      @scaleApp.stopAll()
      @scaleApp.unregisterAll()

    it "is an accessible function", ->
      (expect typeof @scaleApp.stop).toEqual "function"

    it "calls the callback afterwards", (done) ->
      (expect @scaleApp.register "valid", @validModule).toBeTruthy()
      (expect @scaleApp.start "valid").toBeTruthy()
      (expect @scaleApp.stop "valid", done).toBeTruthy()

    it "supports synchronous stopping", ->
      mod = (sb) ->
        init: ->
        destroy: ->
      end = false
      (expect @scaleApp.register "mod", mod).toBeTruthy()
      (expect @scaleApp.start "mod").toBeTruthy()
      (expect @scaleApp.stop "mod", -> end = true).toBeTruthy()
      (expect end).toEqual true

  describe "stopAll function", ->

    beforeEach ->
      @scaleApp.stopAll()
      @scaleApp.unregisterAll()

    it "is an accessible function", ->
      (expect typeof @scaleApp.stopAll).toEqual "function"

    it "stops all running instances", ->
      cb1 = sinon.spy()

      mod1 = (sb) ->
        init: ->
        destroy: -> cb1()

      @scaleApp.register "mod", mod1

      @scaleApp.start "mod", { instanceId: "a" }
      @scaleApp.start "mod", { instanceId: "b" }

      (expect @scaleApp.stopAll()).toBeTruthy()
      (expect cb1.callCount).toEqual 2

    it "calls the callback afterwards", (done) ->
      (expect @scaleApp.register "valid", @validModule).toBeTruthy()
      (expect @scaleApp.start "valid").toBeTruthy()
      (expect @scaleApp.start "valid", instanceId: "valid2").toBeTruthy()
      (expect @scaleApp.stopAll done).toBeTruthy()

    it "calls the callback if not destroyed in a asynchronous way", (done) ->
      cb1 = sinon.spy()
      mod = (sb) ->
        init: ->
        destroy: -> cb1()
      (expect @scaleApp.register "syncDestroy", mod).toBeTruthy()
      (expect @scaleApp.start "syncDestroy").toBeTruthy()
      (expect @scaleApp.start "syncDestroy", instanceId: "second").toBeTruthy()
      (expect @scaleApp.stopAll done).toBeTruthy()

  describe "publish function", ->
    it "is an accessible function", ->
      (expect typeof @scaleApp.publish).toEqual "function"

  describe "subscribe function", ->
    it "is an accessible function", ->
      (expect typeof @scaleApp.subscribe).toEqual "function"

  describe "unsubscribe function", ->

    it "is an accessible function", ->
      (expect typeof @scaleApp.unsubscribe).toEqual "function"

    it "removes subscriptions from a channel", (done) ->

      globalA = sinon.spy()
      globalB = sinon.spy()

      mod = (sb) ->

        init: ->
          sb.subscribe "X", globalA
          sb.subscribe "X", globalB
          sb.subscribe "Y", globalB
          switch sb.instanceId
            when "a"
              localCB = sinon.spy()
              sb.subscribe "X", localCB
            when "b"
              localCB = sinon.spy()
              sb.subscribe "X", localCB
              sb.subscribe "Y", localCB

          sb.subscribe "test1", ->
            switch sb.instanceId
              when "a"
                (expect localCB.callCount).toEqual 3
              when "b"
                (expect localCB.callCount).toEqual 2
            done()

          sb.subscribe "unregister", ->
            if sb.instanceId is "b"
              sb.unsubscribe "X"

        destroy: ->

      (expect @scaleApp.unregisterAll()).toBeTruthy()
      (expect @scaleApp.register "mod", mod).toBeTruthy()
      (expect @scaleApp.start "mod", instanceId: "a").toBeTruthy()
      (expect @scaleApp.start "mod", instanceId: "b").toBeTruthy()

      @scaleApp.publish "X", "foo"
      @scaleApp.publish "Y", "bar"

      (expect globalA.callCount).toEqual 2
      (expect globalB.callCount).toEqual 4
      @scaleApp.publish "test"

      @scaleApp.publish "unregister"
      @scaleApp.publish "X", "foo"

      (expect globalA.callCount).toEqual 3
      (expect globalB.callCount).toEqual 5

      @scaleApp.publish "X"
      @scaleApp.publish "test1"

  describe "registerPlugin function", ->

    beforeEach ->

      @validPlugin =
        id: "myPluginId"
        version: "0.2.4"
        sandbox: (sb) -> { yeah: "great" }
        core: { aKey: "txt", aFunc: -> }
        onInstantiate: (sb, instanceId, opt) ->

    afterEach ->
      @scaleApp.stopAll()
      @scaleApp.unregisterAll()

    it "returns false if plugin is not an object", ->
      (expect @scaleApp.registerPlugin "foo").toBeFalsy()

    it "returns false if sandbox plugin uses reserved keywords", (done) ->

      keys = [
        "core"
        "instanceId"
        "options"
        "publish"
        "subscribe"
        "unsubscribe" ]

      for name in keys
        sbP = {}
        sbP[name] = ->
        plugin =
          id: "myPluginId"
          sandbox: (sb) -> sbP
          core: { }
        (expect @scaleApp.registerPlugin plugin).toBeFalsy()

      for name in keys
        sbP = ->
        sbP::[name] = ->
        plugin =
          id: "myPluginId"
          sandbox: sbP
          core: { }
        (expect @scaleApp.registerPlugin plugin).toBeFalsy()
      done()

    it "returns false if core plugin uses reserved keywords", (done) ->

      keys = [
        "VERSION"
        "register"
        "unregister"
        "unregisterAll"
        "registerPlugin"
        "start"
        "stop"
        "startAll"
        "stopAll"
        "publish"
        "subscribe"
        "unsubscribe"
        "Mediator"
        "Sandbox" ]

      coreKeys = (k for k of @scaleApp)

      (expect k in coreKeys).toBeTruthy() for k in keys

      for name in keys
        p = {}
        p[name] = ->
        plugin =
          id: "myPluginId"
          sandbox: (sb) -> { }
          core: p
        (expect @scaleApp.registerPlugin plugin).toBeFalsy()
      done()

    it "returns true if core plugin uses non-reserved keywords", (done) ->

      keys = [
        "ImFree"
        "foo"
        "bar"
        "blub" ]

      for name in keys
        p = {}
        p[name] = ->
        plugin =
          id: "myPluginId"
          sandbox: (sb) -> { }
          core: p
        (expect @scaleApp.registerPlugin plugin).toBeTruthy()
      done()

    it "returns true if plugin is valid", ->
      (expect @scaleApp.registerPlugin @validPlugin).toBeTruthy()
      (expect @scaleApp.register "nice", @validModule).toBeTruthy()
      (expect @scaleApp.start "nice").toBeTruthy()

    it "installs the core plugin", ->
      (expect @scaleApp.registerPlugin @validPlugin).toBeTruthy()
      (expect @scaleApp.aKey).toEqual "txt"
      (expect @scaleApp.aFunc).toEqual @validPlugin.core.aFunc
      (expect @scaleApp.aFunc).not.toEqual ->

    it "installs the sandbox plugin", (done) ->
      aModule = (sb) ->
        init: ->
          (expect sb.yeah).toEqual "great"
          done()
        destroy: ->
      @scaleApp.register "anId", aModule
      @scaleApp.registerPlugin @validPlugin
      @scaleApp.start "anId"
