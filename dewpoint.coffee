module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  types = env.require('decl-api').types

  class DewPointPlugin extends env.plugins.Plugin
    
    init: (app, @framework, @config) =>
      env.logger.info("Hello new World")
      deviceConfigDef = require("./device-config-schema")
      
      @framework.deviceManager.registerDeviceClass("DewPointDevice", {
        configDef: deviceConfigDef.DewPointDevice, 
        createCallback: (config, lastState) => 
          return new DewPointDevice(config, lastState)
      })

  plugin = new DewPointPlugin

  class DewPointDevice extends env.devices.Device

    temperature: 0.0
    humidity: 0.0
    dewPoint: 0.0

    attributes:
      temperature:
        description: "Temperature"
        type: types.number
        unit: "°C"
        acronym: 'T'
      humidity:
        description: "Relative Humidity"
        type: types.number
        unit: "%"
        acronym: 'RH'
      dewPoint:
        description: "Dew Point Temperature"
        type: types.number
        unit: "°C"
        acronym: 'DT'

    constructor: (@config, lastState) ->
      @id = config.id
      @name = config.name
      @temperature= lastState?.temperature?.value or 0.0;
      @humidity= lastState?.humidity?.value or 0.0;
      @dewPoint= lastState?.dewPoint?.value or 0.0;
      @varManager = plugin.framework.variableManager #so you get the variableManager
      @_exprChangeListeners = []

      for reference in [
        {name: "temperature", expression: config.temperatureRef},
        {name: "humidity", expression: config.humidityRef}
      ]
        do (reference) =>
          name = reference.name
          info = null

          evaluate = ( =>
            # wait till VariableManager is ready
            return Promise.delay(10).then( =>
              unless info?
                info = @varManager.parseVariableExpression(reference.expression)
                @varManager.notifyOnChange(info.tokens, evaluate)
                @_exprChangeListeners.push evaluate

              switch info.datatype
                when "numeric" then @varManager.evaluateNumericExpression(info.tokens)
                when "string" then @varManager.evaluateStringExpression(info.tokens)
                else assert false
            ).then( (val) =>
              if val
                env.logger.debug name, val
                @_setAttribute name, val
                @doYourStuff()
              return @[name]
            )
          )
          @_createGetter(name, evaluate)
      super()

    doYourStuff: ->
      a=7.5
      b=237.3

      sdd=6.1078 * Math.pow(10,(a*@temperature)/(b+@temperature))
      dd=sdd*(@humidity/100)
      v=Math.log(dd/6.1078)/Math.log(10)
      td=(b*v)/(a-v)
      env.logger.debug 'dewPoint', td
      @_setAttribute 'dewPoint', td

    _setAttribute: (attributeName, value) ->
      if @[attributeName] isnt value
        @[attributeName] = value
        @emit attributeName, value

    # getters for temperature & humidity are created by the constructor using @_createGetter method
    getDewPoint: -> Promise.resolve(@dewPoint)

  return plugin