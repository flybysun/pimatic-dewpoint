module.exports = {
  title: "pimatic-dewpoint device config schemas"
  DewPointDevice: {
    title: "DewPointDevice config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      interval:
        description: "Interval in ms so read the sensor"
        type: "number"
        default: "10000"
      temperatureRef:
        description: "Holds the reference to the temperature variable to be read"
        type: "string"
      humidityRef:
        description: "Holds the reference to the humidity variable to be read"
        type: "string"
      units:
        description: "Units used for Temperature (metric/imperial/standard)"
        format: "string"
        default: "metric"
  }
}