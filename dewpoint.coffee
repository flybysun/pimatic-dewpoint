module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  types = env.require('decl-api').types
  _ = env.require 'lodash'

  class DewPointPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
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
    absHumidity: 0.0
    windspeed: 0.0
    windchill: 0.0

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
      absHumidity:
        description: "Absolute Humidity"
        type: types.number
        unit: "g/m³"
        acronym: "AH"
      windspeed:
        description: "Windspeed"
        type: types.number
        unit: "km/h"
        acronym: 'WS'
      windchill:
        description: "Windchill Temperature"
        type: types.number
        unit: "°C"
        acronym: 'WCT'


    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      @temperature = lastState?.temperature?.value or 0.0;
      @humidity = lastState?.humidity?.value or 0.0;
      @dewPoint = lastState?.dewPoint?.value or 0.0;
      @absHumidity = lastState?.absHumidity?.value or 0.0;
      @windchill = lastState?.windchill?.value or 0.0;
      @windspeed = lastState?.windspeed?.value or 0.0;
      
      #@heatindex = lastState?.heatindex?.value or 0.0;
      @units = @config.units
      @attributes = _.cloneDeep @attributes
      if @units is "imperial"
        @attributes["temperature"].unit = '°F'
        @attributes["dewPoint"].unit = '°F'
        @attributes["windchill"].unit = '°F'
      else if @units is "standard"
        @attributes["temperature"].unit = 'K'
        @attributes["dewPoint"].unit = 'K'
        @attributes["windchill"].unit = 'K'

      
      @windUnits = @config.windUnits
      @attributes = _.cloneDeep @attributes
      if @windUnits is "ms"
        @attributes["windspeed"].unit = 'm/s'
      else if @windUnits is "kmh"
        @attributes["windspeed"].unit ='km/h'
      else if @windUnits is "mph"
        @attributes["windspeed"].unit ='mph'        
      else if @windUnits is "fts"
        @attributes["windspeed"].unit ='ft/s'
      else if @windUnits is "knots"
        @attributes["windspeed"].unit ='knots'        
        
      @varManager = plugin.framework.variableManager #so you get the variableManager
      @_exprChangeListeners = []

      for reference in [
        {name: "temperature", expression: @config.temperatureRef},
        {name: "humidity", expression: @config.humidityRef}
        {name: "windspeed", expression: @config.windspeedRef}
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
                else
                  assert false
            ).then((val) =>
              if val
                env.logger.debug name, val
                @_setAttribute name, val
                @dewPointCalculation()
              return @[name]
            )
          )
          @_createGetter(name, evaluate)
      super()

    destroy: () ->
      @varManager.cancelNotifyOnChange(cl) for cl in @_exprChangeListeners
      super()

    dewPointCalculation: ->

      t = @_fromUnitTemperature(@temperature)
      
      if t >= 0
        a = 7.5
        b = 237.3
      else
        a = 7.6
        b = 240.7

      sdd = 6.1078 * Math.pow(10, (a * t) / (b + t))
      dd = sdd * (@humidity / 100)
      v = Math.log(dd / 6.1078) / Math.log(10)
      td = (b * v) / (a - v)
      env.logger.debug 'dewPoint', @_toUnitTemperature(td)
      @_setAttribute 'dewPoint', @_toUnitTemperature(td)
      ah = 2.16679 * ((100 * dd) / (273.15 + t))
      env.logger.debug 'absHumidity', ah
      @_setAttribute 'absHumidity', ah

      vw = @_fromUnitWindSpeed(@windspeed)
      vp = Math.pow(vw, 0.16)
      wct = 13.12 + 0.6125 * t - 11.37 * vp + 0.3965 * t * vp
      env.logger.debug 'windchill', @_toUnitTemperature(wct)
      @_setAttribute 'windchill', @_toUnitTemperature(wct)


    _setAttribute: (attributeName, value) ->
      @[attributeName] = value
      @emit attributeName, value

    _fromUnitTemperature: (t) ->
      if @units is "imperial"
        return @_fahrenheitToCelsius t
      else if @units is "standard"
        return @_kelvinToCelsius t
      else
        return t

    _toUnitTemperature: (t) ->
      if @units is "imperial"
        return @_celsiusToFahrenheit t
      else if @units is "standard"
        return @_celsiusToKelvin t
      else
        return t

    _fromUnitWindSpeed: (vw) ->
      if @windUnits is "mph"
        return @_milesToKm vw
      else if @windUnits is "ms"
        return @_msToKm vw
      else if @windUnits is "fts"
        return @_ftsToKm vw
      else if @windUnits is "knots"
        return @_knotsToKm vw    
      else 
        return vw

    _fahrenheitToCelsius: (fahrenheit) ->
      return (fahrenheit - 32) * 5 / 9

    _celsiusToFahrenheit: (celsius) ->
      return celsius * 9 / 5  + 32

    _kelvinToCelsius: (kelvin) ->
      return kelvin - 273.15

    _celsiusToKelvin: (celsius) ->
      return celsius + 273.15
  
    _milesToKm: (miles) ->
      return (miles * 1.60934)

    _msToKm: (ms) ->
      return (ms * 3.6)  
    
    _ftsToKm: (fts) ->  
      return (fts * 1.09728)
  
    _knotsToKm: (knots) ->
      return (knots * 1.852)

    # getters for temperature & humidity are created by the constructor using @_createGetter method
    getDewPoint: -> Promise.resolve(@dewPoint)
    getAbsHumidity: -> Promise.resolve(@absHumidity)
    getWindchill: -> Promise.resolve(@windchill)

  return plugin
