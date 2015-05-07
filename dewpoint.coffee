module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'

  class DewpointPlugin extends env.plugins.Plugin
    
    init: (app, @framework, @config) =>
      env.logger.info("Hello new World")
      deviceConfigDef = require("./device-config-schema")
      
      @framework.deviceManager.registerDeviceClass("DewpointDevice", {
        configDef: deviceConfigDef.DewpointDevice, 
        createCallback: (config, lastState) => 
          return new DewpointDevice(config, lastState)
      })
  
  Dewpoint = new DewpointPlugin
  
  class DewpointDevice extends env.devices.TemperatureSensor
    temperature: null
    T: null
    H: null
    
    constructor: (@config, lastState) ->
      @id = config.id
      @name = config.name
      @temperature = lastState?.temperature?.value
      @T = lastState?.T?.value
      @H = lastState?.H?.value
      @varManager = Dewpoint.framework.variableManager #so you get the variableManager
      @_exprChangeListeners = []
      @attributes = {}
     
      for variable in @config.variables
        do (variable) =>
          name = variable.name
          info = null
          
          @attributes[name] = {
            description: name
            label: (if variable.label? then variable.label else "$#{name}")
            type: variable.type or "string"
          }
          
          evaluate = ( => 
            # wait till veraibelmanager is ready
            return Promise.delay(1).then( =>
              unless info?

                info = @varManager.parseVariableExpression(variable.allocation) 

                @varManager.notifyOnChange(info.tokens, evaluate)
                @_exprChangeListeners.push evaluate
              if @attributes[name].type is "number"
                unless @attributes[name].unit? and @attributes[name].unit.length > 0
                  @attributes[name].unit = @varManager.inferUnitOfExpression(info.tokens)
              switch info.datatype
                when "numeric" then @varManager.evaluateNumericExpression(info.tokens)
                when "string" then @varManager.evaluateStringExpression(info.tokens)
                else assert false
            ).then( (val) =>
              if val isnt @_attributesMeta[name].value
                console.log(name)
                console.log(val)
                console.log(evaluate)
                @emit name, val
                switch variable.name
                  when "humidity" then @H = val
                  when "temperature" then @T = val                
              return val
            )
          )
          @_createGetter(name, evaluate)
      super()
   
      @doYourStuff()
      setInterval( ( => @doYourStuff() ), @config.interval)
 
    doYourStuff: ->
      a=7.5
      b=237.3
      #T=23  #temperature
      #H=40  #humidity

      sdd=6.1078 * Math.pow(10,(a*@T)/(b+@T))
      dd=sdd*(@H/100)
      v=Math.log(dd/6.1078)/Math.log(10)
      td=(b*v)/(a-v)
      
      @temperature = td
      @emit 'temperature', td

    getTemperature: -> Promise.resolve(@temperature)

  return Dewpoint
