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
    windSpeed: 0.0
    windChill: 0.0
    heatIndex: 0.0
    apparentTemperature: 0.0

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
      windSpeed:
        description: "Windspeed"
        type: types.number
        unit: "km/h"
        acronym: 'WS'
      windChill:
        description: "Windchill Temperature"
        type: types.number
        unit: "°C"
        acronym: 'WCT'
      heatIndex:
        description: "Heat Index Temperature"
        type: types.number
        unit: "°C"
        acronym: 'HIT'
      apparentTemperature:
        description: "Apparent Temperature"
        type: types.number
        unit: "°C"
        acronym: 'AT'


    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      @temperature = lastState?.temperature?.value or 0.0
      @humidity = lastState?.humidity?.value or 0.0
      @dewPoint = lastState?.dewPoint?.value or 0.0
      @absHumidity = lastState?.absHumidity?.value or 0.0
      @windSpeed = lastState?.windSpeed?.value or 0.0
      @windChill = lastState?.windChill?.value or 0.0
      @heatIndex = lastState?.heatIndex?.value or 0.0
      @apparentTemperature = lastState?.apparentTemperature?.value or 0.0

      @units = @config.units
      @attributes = _.cloneDeep @attributes
      if @units is "imperial"
        @attributes["temperature"].unit = '°F'
        @attributes["dewPoint"].unit = '°F'
        @attributes["windChill"].unit = '°F'
        @attributes["heatIndex"].unit = '°F'
        @attributes["apparentTemperature"].unit = '°F'
      else if @units is "standard"
        @attributes["temperature"].unit = 'K'
        @attributes["dewPoint"].unit = 'K'
        @attributes["windChill"].unit = 'K'
        @attributes["heatIndex"].unit = 'K'
        @attributes["apparentTemperature"].unit = 'K'

      @windUnits = @config.windUnits
      @attributes["windSpeed"].unit = @windUnits
        
      @varManager = plugin.framework.variableManager #so you get the variableManager
      @_exprChangeListeners = []

      for reference in [
        {name: "temperature", expression: @config.temperatureRef},
        {name: "humidity", expression: @config.humidityRef}
        {name: "windSpeed", expression: @config.windSpeedRef}
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
                @calcValues()
              return @[name]
            )
          )
          @_createGetter(name, evaluate)
      super()

    destroy: () ->
      @varManager.cancelNotifyOnChange(cl) for cl in @_exprChangeListeners
      super()

    calcHeatIndex: (t, rh, dp) ->
      if t < 27 or rh < 40 or dp < 12
        t
      else
        c1 = -8.784695
        c2 = 1.61139411
        c3 = 2.338549
        c4 = -0.14611605
        c5 = -1.2308094 * 0.01
        c6 = -1.6424828 * 0.01
        c7 = 2.211732 * 0.001
        c8 = 7.2546 * 0.0001
        c9 = -3.582 * 0.000001

        prh = rh * rh
        pt = t * t
        c1 + c2*t + c3*rh + c4*t*rh + c5*pt + c6*prh + c7*pt*rh + c8*t*prh + c9*pt*prh

    calcWindChill: (t, vw) ->
      if t >= 10
        t
      else
        if vw >= 4.8 and vw <= 177
          13.12 + 0.6215 * t + (0.3965 * t - 11.37) * Math.pow(vw, 0.16)
        else if vw < 4.8
          t + 0.2 * (0.1345 * t - 1.59) * vw
        else
          t

    calcValues: ->
      t = @_fromUnitTemperature(@temperature)

      # dewPoint
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

      # absHumidity
      ah = 2.16679 * ((100 * dd) / (273.15 + t))
      env.logger.debug 'absHumidity', ah
      @_setAttribute 'absHumidity', ah

      # windChill
      vw = @_fromUnitWindSpeed(@windSpeed)
      wct = @calcWindChill t, vw
      env.logger.debug 'windChill', @_toUnitTemperature(wct)
      @_setAttribute 'windChill', @_toUnitTemperature(wct)

      # heatIndex
      hit = @calcHeatIndex(t, @humidity, td)
      env.logger.debug 'heatIndex', @_toUnitTemperature(hit)
      @_setAttribute 'heatIndex', @_toUnitTemperature(hit)

      # apparentTemperature
      at = if t < 10 then vw else hit
      env.logger.debug 'apparentTemperature', @_toUnitTemperature(at)
      @_setAttribute 'apparentTemperature', @_toUnitTemperature(at)

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
      if @windUnits is "mp/h"
        return @_milesToKm vw
      else if @windUnits is "m/s"
        return @_msToKm vw
      else if @windUnits is "ft/s"
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
    getWindChill: -> Promise.resolve(@windChill)
    getHeatIndex: -> Promise.resolve(@heatIndex)
    getApparentTemperature: -> Promise.resolve(@apparentTemperature)

  return plugin
