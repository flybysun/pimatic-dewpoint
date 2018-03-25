module.exports = {
  title: "pimatic-dewpoint device config schemas"
  DewPointDevice: {
    title: "DewPointDevice config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      interval:
        description: "Interval in ms to read the sensor"
        type: "number"
        default: "10000"
      temperatureRef:
        description: "Holds the reference to the temperature variable to be read"
        type: "string"
        default: "0.0"
      humidityRef:
        description: "Holds the reference to the humidity variable to be read"
        type: "string"
        default: "0"
      windSpeedRef:
        description: "Holds the reference to the wind speed to be read"
        type: "string"
        default: "0.0"
      units:
        description: "Units used for Temperature (metric/imperial/standard)"
        enum: ["metric", "imperial", "standard"]
        default: "metric"
      windUnits:
        description: "Units used for the Wind Speed (m/s, km/h, ft/s, mph, knots)"
        enum: ["m/s", "km/h", "ft/s", "m/ph", "knots"]
        default: "km/h"
  }
}
