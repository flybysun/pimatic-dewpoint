module.exports ={
  title: "pimatic-dewpoint device config schemas"
  DewpointDevice: {
    title: "DewpointDevice config options"
    type: "object"
    extensions: ["xLink"]
    properties: 
      interval:
        interval: "Interval in ms so read the sensor"
        type: "integer"
        default: "1000"
      variables:
        description: "Variable of the device"
        type: "array"        
  }
}
